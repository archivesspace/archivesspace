require_relative 'converter'
require 'nokogiri'
require 'pp'
require 'rubyXL'
require 'asutils'
class BulkImportConverter < Converter
  def self.import_types(_show_hidden = false)
    [
      {
        name: 'bulk_import_excel',
        description: 'Import Import Archival and Digital Objects from an Excel Spreadsheet'
      }
    ]
  end

  def self.instance_for(type, input_file, opts = {})
    new(input_file, opts) if type == 'bulk_import_excel'
  end

  def run
    Log.error('RUN')
    initialize_info
  end

  

  def initialize(input_file, opts = {})
    @input_file = input_file
   # @batch = ASpaceImport::RecordBatch.new
    @opts = opts
    Log.error("OPTS: #{@opts}")
    initialize_handler_enums
    # WAAY more initialization to come
  end
  # this refreshes the controlled list enumerations, which may have changed since the last import
  
  
  private

  # set up all the @ variables (except for @header)
  def initialize_info
    @orig_filename = @opts[:filename]
    @report_out = []
    @report = BulkImportTracker.new
    @headers
    @digital_load = @opts[:digital_load] == 'true'
    @report.set_file_name(@orig_filename)
    # initialize_handler_enums
    @resource = Resource.get_or_die(@opts[:rid])
    Log.error("BulkImport got resource: #{@resource.inspect}")
    Log.error("BulkImport repo_id match? #{@opts[:repo_id] == @resouce[:repo_id]}")
    @repository = Repository.get_or_die(@opts[:repo_id])
    Log.error("BulkImport got repo: #{@repository.inspect}")
    @hier = 1
    # ingest archival objects needs this
    unless @digital_load
      @ao = nil
      aoid = @opts[:aoid] || nil
      @resource_level = aoid.nil?
      @first_one = false # to determine whether we need to worry about positioning
      if @resource_level
        @parents.set_uri(0, nil)
        @hier = 0
      else
        @ao = JSONModel(:archival_object).find(aoid, find_opts)
        @start_position = @ao.position
        parent = @ao.parent # we need this for sibling/child disabiguation later on
        @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)['ref'] : nil))
        @parents.set_uri(1, @ao.uri)
        @first_one = true
      end
    end
    @input_file = dispatched_file_path
    @counter = 0
    @rows_processed = 0
    @error_rows = 0
    Log.error("About to open #{@input_file}")
    workbook = RubyXL::Parser.parse(@input_file)
    Log.error('Got workbook ')
    sheet = workbook[0]
    Log.error('Got sheet: ')
    rows = sheet.enum_for(:each)
  end

  def row_values(row)
    (1...row.size).map {|i| (row[i] && row[i].value) ? (row[i].value.to_s.strip.empty? ? nil : row[i].value.to_s.strip) : nil}
  end

end
