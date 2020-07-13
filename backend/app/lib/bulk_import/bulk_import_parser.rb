require_relative "bulk_import_mixins"
require_relative "../uri_resolver"
require "nokogiri"
require "pp"
require "rubyXL"
require "csv"
require "asutils"
include URIResolver

MAX_FILE_SIZE = Integer(AppConfig[:bulk_import_size])
MAX_FILE_ROWS = Integer(AppConfig[:bulk_import_rows])
MAX_FILE_INFO = I18n.t("bulk_import.max_file_info", :rows => MAX_FILE_ROWS, :size => MAX_FILE_SIZE)

# Base class for bulk import via spreadsheet; handles both CSV's and excel spreadsheets
# This class is designed for spreadsheets with the following features:
#  1. There may be multiple rows of headers, each of which have *something* in the
#     0th column
#  2. The header row containing the internal (machine-readble) labels will have in
#     its 0th
#     some defined string; this string shall be used in the sub-class's START_MARKER constant
#  3. Only header rows contain strings in their 0th column; data rows will have an
#     empty 0th column.  This means that there can be an arbitrary (including 0)
#     number of header rows *after* the internal labels row; the code can handle it!
#  4. The various handler classes are now required in the *bulk_import_mixins.rb* file.
#  5. The method that must be implemented in the sub class is *process_row*
#
class BulkImportParser
  def run
    begin
      initialize_info
      begin
        while (row = @rows.next)
          @counter += 1
          values = row_values(row)
          next if !values[0].nil?  # header rows all have something in the first column
          next if values.reject(&:nil?).empty?
          @row_hash = Hash[@headers.zip(values)]
          begin
            @report.new_row(@counter)
            process_row
            @rows_processed += 1
            @error_level = nil
          rescue StopBulkImportException => se
            @report.add_errors(I18n.t("bulk_import.error.stopped", :row => @counter, :msg => se.message))
            raise StopIteration.new
          rescue BulkImportException => e
            @error_rows += 1
            @report.add_errors(e.message)
            @error_level = @hier
          end
          @report.end_row
        end
      rescue StopIteration
        # we just want to catch this without processing further
      end
      if @rows_processed == 0
        raise BulkImportException.new(I18n.t("bulk_import.error.no_data"))
      end
    rescue Exception => e
      if e.is_a?(BulkImportException) || e.is_a?(StopBulkImportException)
        @report.add_terminal_error(I18n.t("bulk_import.error.excel", :errs => e.message), @counter)
      elsif e.is_a?(StopIteration) && @headers.nil?
        @report.add_terminal_error(I18n.t("bulk_import.error.no_header"), @counter)
      else # something else went wrong
        @report.add_terminal_error(I18n.t("bulk_import.error.system", :msg => e.message), @counter)
        Log.error("UNEXPECTED EXCEPTION on bulkimport load! #{e.message}")
        Log.error(e.backtrace.pretty_inspect)
      end
    end
    return @report
  end

  def initialize(input_file, content_type, current_user, opts)
    @input_file = input_file
    @extension = File.extname(@input_file).strip.downcase
    @file_content_type = content_type
    @opts = opts
    @current_user = current_user
    @report_out = []
    @report = BulkImportReport.new
    @start_position
    @need_to_move = false
    @is_xslx = file_is_xslx?
    @is_csv = file_is_csv?
    initialize_handler_enums
    @counter = 0
  end

  def initialize_handler_enums
    #initialize handlers, if needed
  end

  # set up all the @ variables
  def initialize_info
    @orig_filename = @opts[:filename]
    @report_out = []
    @report = BulkImportReport.new
    @headers
    @report.set_file_name(@orig_filename)
    @resource = resolve_references(Resource.to_jsonmodel(@opts[:rid]), ["repository"])
    @repository = @resource["repository"]["ref"]
    @hier = 1
    @counter = 0
    @rows_processed = 0
    @error_rows = 0
    raise StopBulkImportException.new(I18n.t("bulk_import.error.wrong_file_type", :content_type => @file_content_type, :extension => @extension)) if !@is_csv && !@is_xslx
    #XSLX
    if @is_xslx
      workbook = RubyXL::Parser.parse(@input_file)
      sheet = workbook[0]
      @rows = sheet.enum_for(:each)
      number_rows = sheet.sheet_data.rows.size
      size = (File.size?(@input_file).to_f / 1000).round
      file_info = I18n.t("bulk_import.file_info", :rows => number_rows, :size => size)
      if size > MAX_FILE_SIZE || number_rows > MAX_FILE_ROWS
        raise BulkImportException.new(I18n.t("bulk_import.error.file_too_big", :limits => MAX_FILE_INFO, :file_info => file_info))
      end
      @rows = sheet.enum_for(:each)
      #CSV
    elsif @is_csv
      table = CSV.read(@input_file)
      @rows = table.enum_for(:each)
    end
    find_headers
  end

  private

  def file_is_xslx?
    return @file_content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || @extension == ".xslx"
  end

  #MS Excel in Windows assigns a CSV file a mime type of application/vnd.ms-excel
  #The other suggestions are also some variations of other csv mime types found.  This is a catch-all
  def file_is_csv?
    return @file_content_type == "text/csv" || @file_content_type == "text/plain" \
    || @file_content_type == "text/x-csv" \
    || @file_content_type == "application/vnd.ms-excel" \
    || @file_content_type == "application/csv" \
    || @file_content_type == "application/x-csv" \
    || @file_content_type == "text/comma-separated-values" \
    || @file_content_type == "text/x-comma-separated-values" \
    || @extension == ".csv"
  end

  def find_headers
    while @headers.nil? && (row = @rows.next)
      @counter += 1
      value = row[0]
      if @is_xslx
        value = row[0] ? row[0].value.to_s : nil
      end
      if (value =~ self.class::START_MARKER)
        @headers = row_values(row)
      end
    end
    begin
      check_for_code_dups
    rescue Exception => e
      raise StopBulkImportException.new(e.message)
    end
  end

  def row_values(row)
    values = row
    if @is_xslx
      values = (0...row.size).map { |i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil }
    else
      values = (0...values.size).map { |i| (values[i]) ? (values[i].to_s.strip.empty? ? nil : values[i].to_s.strip) : nil }
    end
    values
  end

  def check_row
    # overwrite this
    []
  end

  def check_for_code_dups
    test = {}
    dups = ""
    @headers.each do |head|
      if test[head]
        dups = "#{dups} #{head},"
      else
        test[head] = true
      end
    end
    if !dups.empty?
      raise Exception.new(I18n.t("bulk_import.error.duplicates", :codes => dups))
    end
  end

  # IMPLEMENT THIS IN YOUR bulk_import_parser CLASS
  def process_row
    # overwrite this class
  end
end
