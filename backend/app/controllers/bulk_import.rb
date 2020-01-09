class ArchivesSpaceService < Sinatra::Base
  require "pp"
  require "nokogiri"
  require "rubyXL"
  #Supports bulk import of spreadsheets
  Endpoint.post("/bulkimport/ssload")
    .description("Bulk Import an Excel Spreadsheet")
    .params(["repo_id", :repo_id],
            ["rid", :id],
            ["ref_id", String, "Ref ID"],
            ["position", String, "Position in tree"],
            ["type", String, "resource or archival_object"],
            ["aoid", String, "archival object ID"],
            ["filename", String, "the original file name"],
            ["filepath", String, "the spreadsheet temp path"])
    .permissions([:update_resource_record])
    .returns([200, "HTML"],
             [400, :error]) do
    #right now, just return something!
    @rows = initialize_info(params)
    Log.error("Number of rows: #{@rows.count}")
    erb :'bulk/bulk_import_response'
  end
  # set up all the @ variables (except for @header)
  def initialize_info(params)
    dispatched_file_path = params[:filepath]
    @orig_filename = params[:filename]
    # @report.set_file_name(@orig_filename)
    # initialize_handler_enums
    # @resource = Resource.find(params[:rid])
    # @repository = @resource['repository']['ref']
    # @hier = 1
    # ingest archival objects needs this
    # unless @digital_load
    #   @note_types =  note_types_for(:archival_object)
    #   tree = JSONModel(:resource_tree).find(nil, :resource_id => params[:rid]).to_hash
    #  @ao = nil
    #   aoid = params[:aoid]
    #   @resource_level = aoid.blank?
    #   @first_one = false  # to determine whether we need to worry about positioning
    #   if @resource_level
    #     @parents.set_uri(0, nil)
    #     @hier = 0
    #   else
    #     @ao = JSONModel(:archival_object).find(aoid, find_opts )
    #     @start_position = @ao.position
    #     parent = @ao.parent # we need this for sibling/child disabiguation later on
    #     @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)['ref'] : nil))
    #     @parents.set_uri(1, @ao.uri)
    #     @first_one = true
    #   end
    # end

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
