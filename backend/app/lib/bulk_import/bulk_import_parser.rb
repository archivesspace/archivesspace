require_relative "bulk_import_mixins"
require_relative "../uri_resolver"
require "nokogiri"
require "pp"
require "rubyXL"
require "csv"
require "asutils"

# Base class for bulk import via spreadsheet; handles both CSV's and excel spreadsheets
# This class is designed for spreadsheets with the following features:
#  1. There may be multiple rows of headers, each of which have *something* in the
#     0th column
#  2. The header row containing the internal (machine-readble) labels will have in
#     its 0th column some defined string;
#     this string shall be used in the sub-class's START_MARKER constant
#  3. Only header rows contain strings in their 0th column; data rows will have an
#     empty 0th column.  This means that there can be an arbitrary (including 0)
#     number of header rows *after* the internal labels row; the code can handle it!
#  4. The various handler classes are now required in the *bulk_import_mixins.rb* file.
#  5. The methods that must be implemented in the sub class are *process_row*
#      and *log_row*
#
class BulkImportParser
  include URIResolver
  include BulkImportMixins
=begin
  MAX_FILE_SIZE = Integer(AppConfig[:bulk_import_size])
  MAX_FILE_ROWS = Integer(AppConfig[:bulk_import_rows])
  MAX_FILE_INFO = I18n.t("bulk_import.max_file_info", :rows => MAX_FILE_ROWS, :size => MAX_FILE_SIZE)
=end

  def initialize(input_file, content_type, current_user, opts, log_method)
    @created_refs = []
    @input_file = input_file
    @file_content_type = content_type
    @opts = opts
    @current_user = current_user
    @report_out = []
    @report = BulkImportReport.new
    @start_position
    @need_to_move = false
    @log_method = log_method
    @is_xslx = @file_content_type == "xlsx"
    @is_csv = @file_content_type == "csv"
    @validate_only = opts[:validate]
  end

  def record_uris
    @created_refs
  end

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
          current = @report.current_row
          log_row(current) unless @log_method.nil?
          @report.end_row
        end
      rescue StopIteration
        # we just want to catch this without processing further
      end
      if @rows_processed == 0
        message = I18n.t("bulk_import.error.no_data") # default message (no data)
        if @report.current_row && @report.current_row.errors.any?
          # if we have a row error message put that into the exception so it more closely matches the csv report
          message = @report.current_row.errors.first.match(/\[(.*)\]/)[1]
        end
        raise BulkImportException.new(message)
      end
    rescue Exception => e
      if e.is_a?(BulkImportException) || e.is_a?(StopBulkImportException)
        @report.add_terminal_error(I18n.t("bulk_import.error.spreadsheet", :errs => e.message), @counter)
      elsif e.is_a?(StopIteration) && @headers.nil?
        @report.add_terminal_error(I18n.t("bulk_import.error.no_header"), @counter)
      elsif e.is_a?(ArgumentError)
        @report.add_terminal_error(I18n.t("bulk_import.error.utf8"), @counter)
      else # something else went wrong
        @report.add_terminal_error(I18n.t("bulk_import.error.system", :msg => e.message), @counter)
        Log.error("UNEXPECTED EXCEPTION on bulkimport load! #{e.message}")
        Log.error(e.backtrace.pretty_inspect)
      end
    end
    return @report
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
    initialize_handler_enums
    jsonresource = Resource.to_jsonmodel(Integer(@opts[:rid]))
    @resource = resolve_references(jsonresource, ["repository"])
    @repository = @resource["repository"]["ref"]
    @hier = 1
    @counter = 0
    @rows_processed = 0
    @error_rows = 0
    raise StopBulkImportException.new(I18n.t("bulk_import.error.wrong_file_type")) if !@is_csv && !@is_xslx
    #XSLX
    if @is_xslx
      workbook = RubyXL::Parser.parse(@input_file)
      sheet = workbook[0]
      @rows = sheet.enum_for(:each)
      #CSV
    elsif @is_csv
      table = CSV.read(@input_file)
      @rows = table.enum_for(:each)
    end
    find_headers
  end

  private

  def find_headers
    while @headers.nil? && (row = @rows.next)
      @counter += 1
      values = row_values(row)
      if (values[0] =~ self.class::START_MARKER)
        @headers = values
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
      if head
        if test[head]
          dups = "#{dups} #{head},"
        else
          test[head] = true
        end
      end
    end
    if !dups.empty?
      raise Exception.new(I18n.t("bulk_import.error.duplicates", :codes => dups))
    end
  end

  # IMPLEMENT THIS IN YOUR bulk_import_parser sub-class
  def process_row
    # overwrite this class
  end

  # IMPLEMENT THIS IN YOUR bulk_import_parser sub-class if you want logging
  #  Presumes that a logging method was passed in as a parameter
  def log_row(row)
    #overwrite this class
  end
end
