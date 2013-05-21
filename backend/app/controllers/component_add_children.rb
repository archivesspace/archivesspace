class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources/:resource_id/children')
  .description("Add children to a Resource")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the resource", :body => true],
          ["resource_id", Integer, "The ID of the resource to add children to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    resource = Resource.get_or_die(params[:resource_id])

    resource.add_children(params[:children])

    updated_response(resource)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/children')
  .description("Add children to an Archival Object")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the resource", :body => true],
          ["id", Integer, "The ID of the archival object to add children to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])

    ao.add_children(params[:children])

    updated_response(ao)
  end


end
