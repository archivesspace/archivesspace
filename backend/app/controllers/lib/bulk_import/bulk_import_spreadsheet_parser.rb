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
require 'csv'
include URIResolver



#This class assists in parsing the spreadsheet and should be inherited
#It has the capability to parse either CSV or XSLX
#This assumes that the first row are internal IDs and the 
#second row has human readable headers. Data then begins on the 3rd row
class BulkImportSpreadsheetParser
  
  #Column constants
  REF_ID = "ref_id"
  INSTANCE_TYPE = "instance_type"
  TOP_CONTAINER_INDICATOR = "top_container_indicator"
  TOP_CONTAINER_ID = "top_container_id"
  TOP_CONTAINER_TYPE = "top_container_type"
  TOP_CONTAINER_BARCODE = "top_container_barcode"
  CHILD_TYPE = "child_type"
  CHILD_INDICATOR = "child_indicator"
  LOCATION_ID = "location_id"
  CONTAINER_PROFILE_ID = "container_profile_id"
  EAD_ID = "ead_id"
  
  #This is in column 1 and is the row in which the field names (above) reside
  AS_FIELD_CODE = "ArchivesSpace field code (please don't edit this row)"
  
  attr_reader :report
  
  def initialize(input_file, file_content_type, opts = {}, current_user)
    @input_file = input_file
    @extension = File.extname(@input_file).strip.downcase
    @current_user = current_user
    @file_content_type = file_content_type
    @opts = opts
    @headers = nil
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
    @counter = 0
    @rows_processed = 0
    @error_rows = 0
    
    #XSLX
    if file_is_xslx?
      workbook = RubyXL::Parser.parse(@input_file)
      sheet = workbook[0]
      @rows = sheet.enum_for(:each)
    #CSV
    elsif file_is_csv?
      begin
        table = CSV.read(@input_file)
      rescue Exception => e
        raise StopBulkImportException.new(I18n.t("bulk_import.error.csv_parsing_failed", :why => e.message))
      end
      @rows = table.enum_for(:each)
    end
    set_up_headers
    
    begin
      peek = @rows.peek
      #Move to the first row of data
      while (!peek.nil? && !peek[0].nil?)  
        values = row_values(peek)
        #When the first column is blank, that is the first row of data
        if (values[0].nil?)
          break
        end
        row = @rows.next
        peek = @rows.peek
      end  
    rescue StopIteration
      #This should never happen because the headers and data will be populated
      #but catch it just in case
      raise StopBulkImportException.new(I18n.t("bulk_import.error.premature_stop_iteration"))
    end  
    @rows
  end
  
  #Get a hash for the row where the headers are keys
  def get_row_hash(values)
    values = row_values(values)
    return Hash[@headers.zip(values)]
  end

  private
  
  def file_is_xslx?
    return @file_content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || @extension == '.xslx'
  end
  def file_is_csv?
    return @file_content_type == 'text/csv' || @extension == '.csv'
  end 
  

  #Sets up the headers 
  #This looks for the field code in column 1
  def set_up_headers()
    begin
      while @headers.nil? && (row = @rows.next)
        @counter += 1
        headers = row_values(row)
        #Look for the field code row
        if (headers[0] == AS_FIELD_CODE)
          @headers = headers
        end
      end
    rescue StopIteration
      #This should never happen because the headers will be populated
      #but catch it just in case
      raise StopBulkImportException.new(I18n.t("bulk_import.error.premature_stop_iteration"))
     end
    
    begin
      check_for_code_dups(@headers)
    rescue Exception => e
      raise StopBulkImportException.new(e.message)
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
    if file_is_xslx?
      (0...row.size).map { |i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil }
    elsif file_is_csv?
      (0...row.size).map { |i| (row[i] && row[i]) ? (row[i].strip.empty? ? nil : row[i].strip) : nil }
    end
  end
end