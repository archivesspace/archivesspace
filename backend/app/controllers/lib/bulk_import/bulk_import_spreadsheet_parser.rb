require_relative "bulk_import_mixins"
require_relative "cv_list"
require_relative "agent_handler"
require_relative "container_instance_handler"
require_relative "digital_object_handler"
require_relative "lang_handler"
require_relative "notes_handler"
require_relative "subject_handler"
require_relative "../../../lib/uri_resolver"
require "nokogiri"
require "pp"
require "rubyXL"
require "asutils"
include URIResolver



#This class assists in parsing the spreadsheet and should be inherited
#It has the capability to parse either CSV or XSLX
#This assumes that the first row are internal IDs and the 
#second row has human readable headers. Data then begins on the 3rd row
class BulkImportSpreadsheetParser
  attr_reader :report
  
  def initialize(input_file, file_content_type, opts = {}, current_user)
    @input_file = input_file
    @extension = File.extname(@input_file).strip.downcase
    @current_user = current_user
    @file_content_type = file_content_type
    @opts = opts
    @xslx_headers = nil
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:rid]}"
    @repo_id = opts[:repo_id]
  end
  
  # set up all the @ variables (except for @header)
  #This method is called during the 'run' cycle so that it is initialized
  #when processing is ready to begin.
  def initialize_info
    @orig_filename = @opts[:filename]
    @report_out = []
    @report = BulkImportReport.new
    @report.set_file_name(@orig_filename)
    #Start the counter at 2 since the headers
    #are in the first two rows
    @counter = 2
    @rows_processed = 0
    @error_rows = 0
    
    #XSLX
    if file_is_xslx?
      workbook = RubyXL::Parser.parse(@input_file)
      sheet = workbook[0]
      @rows = sheet.enum_for(:each)
      set_up_xslx_headers
    #CSV
    elsif file_is_csv?
      table = CSV.read(@input_file, headers: true)
      @rows = table.enum_for(:each)
      # Skip the human readable header
      hr_row = @rows.next
      begin
        check_for_code_dups(hr_row)
      rescue Exception => e
        raise StopBulkImportException.new(e.message)
      end
    end
    @rows
  end
  
  #Get a hash for the row where the headers are keys
  def get_row_hash(values)
    if file_is_xslx?
      values = row_values(values)
      return Hash[@xslx_headers.zip(values)]
    elsif file_is_csv?
      return values.to_h
    end
  end

  private
  
  def file_is_xslx?
    return @file_content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || @extension == '.xslx'
  end
  def file_is_csv?
    return @file_content_type == 'text/csv' || @extension == '.csv'
  end 
  

  #Sets up the headers for an excel spreadsheet
  #This assumes that the first row are internal IDs and the 
  #second row has human readable headers. Data then begins on the 3rd row
  def set_up_xslx_headers()
    while @xslx_headers.nil? && (row = @rows.next)
      @xslx_headers = row_values(row)
      begin
        check_for_code_dups(@xslx_headers)
      rescue Exception => e
        raise StopBulkImportException.new(e.message)
      end
      # Skip the human readable header
      @rows.next
    end
  end
  
  #Checks to see if any of the xlsx headers are duplicated
  #If so, an error is thrown.
  def check_for_code_dups(headers)
    test = {}
    dups = ""
    headers.each do |head|
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
  

  def row_values(row)
    (1...row.size).map { |i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil }
  end
end