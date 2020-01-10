require_relative "converter"
require_relative "lib/bulk_import/bulk_import_tracker"
require "nokogiri"
require "pp"
require "rubyXL"
require "asutils"

START_MARKER = /ArchivesSpace field code/
DO_START_MARKER = /ArchivesSpace digital object import field codes/
#set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :load_ss, :load_dos]

class BulkImportConverter < Converter
  def self.import_types(show_hidden = false)
    [
      {
        :name => "bulk_import_excel",
        :description => "Import Import Archival and Digital Objects from an Excel Spreadsheet",
      },
    ]
  end
  def self.instance_for(type, input_file, opts = {})
    if type == "bulk_import_excel"
      self.new(input_file, opts)
    else
      nil
    end
  end

  def run
    Log.error("RUN")
  end

  def initialize(input_file, opts = {})
    @input_file = input_file
    @batch = ASpaceImport::RecordBatch.new
    @opts = opts
    Log.error("OPTS: #{@opts}")
  end

  private

  # set up all the @ variables (except for @header)
  def initialize_info
    @orig_filename = @opts[:filename]
    @report_out = []
    @report = BulkImportTracker.new
    @headers
    @digital_load = @opts[:digital_load] == "true"
    @report.set_file_name(@orig_filename)
    # initialize_handler_enums
    @resource = Resource.find(@opts[:rid])
    @repository = @resource["repository"]["ref"]
    @hier = 1
    # ingest archival objects needs this
    unless @digital_load
      @note_types = note_types_for(:archival_object)
      tree = JSONModel(:resource_tree).find(nil, :resource_id => @opts[:rid]).to_hash
      @ao = nil
      aoid = @opts[:aoid] || nil
      @resource_level = aoid.nil?
      @first_one = false  # to determine whether we need to worry about positioning
      if @resource_level
        @parents.set_uri(0, nil)
        @hier = 0
      else
        @ao = JSONModel(:archival_object).find(aoid, find_opts)
        @start_position = @ao.position
        parent = @ao.parent # we need this for sibling/child disabiguation later on
        @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)["ref"] : nil))
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
    Log.error("Got workbook ")
    sheet = workbook[0]
    Log.error("Got sheet: ")
    rows = sheet.enum_for(:each)
  end
end
