class ArchivesSpaceService < Sinatra::Base
  
  include ExportHelpers

  Endpoint.get('/repositories/:repo_id/resource_descriptions/:resource_id.ead')
    .description("Get an EAD representation of a Resource ")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id])
    .returns([200, "(:resource)"]) \
  do
    xml = serialize(params[:resource_id], :resource, params[:repo_id])
    
    xml_response(xml)    
  end
  
end