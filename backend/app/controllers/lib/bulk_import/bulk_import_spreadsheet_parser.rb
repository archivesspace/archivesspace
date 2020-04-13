require_relative "bulk_import_mixins"
require_relative "../../../lib/uri_resolver"
require "nokogiri"
require "pp"
require "rubyXL"
require "asutils"
require 'csv'
include URIResolver

#This class assists in parsing the spreadsheet and should be inherited
#It has the capability to parse either CSV or XSLX
class BulkImportSpreadsheetParser
  def initialize(input_file, file_content_type, opts = {}, current_user)
    @input_file = input_file
    @extension = File.extname(@input_file).strip.downcase
    @current_user = current_user
    @file_content_type = file_content_type
    @opts = opts
    @headers = nil
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
      @headers = row_values(@rows.next)
    #CSV
    elsif file_is_csv?
      table = CSV.read(@input_file, headers: true)
      @rows = table.enum_for(:each)
    end
  end
  
  def get_row_hash(values)
    if file_is_xslx?
      values = row_values(values)
      return Hash[@headers.zip(values)]
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
  
  def row_values(row)
    (1...row.size).map { |i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil }
  end
end