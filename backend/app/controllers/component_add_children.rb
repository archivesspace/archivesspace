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
  .params(["children", JSONModel(:archival_record_children), "The children to add to the archival object", :body => true],
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


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/accept_children')
  .description("Move existing archival objects to become children of an Archival Object")
  .params(["children", [String], "The children to move to the archival object",:optional => true],
          ["id", Integer, "The ID of the archival object to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    start_index = params[:position]

    params[:children].each_with_index do |ao_uri, i|
      child_ao = ArchivalObject.get_or_die(JSONModel(:archival_object).id_for(ao_uri))
      child_ao.update_position_only(params[:id], start_index + i)
    end

    updated_response(ao)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/accept_children')
  .description("Move existing archival objects to become children of a Resource")
  .params(["children", [String], "The children to move to the resource",:optional => true],
          ["id", Integer, "The ID of the resource to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    resource = Resource.get_or_die(params[:id])
    start_index = params[:position]

    params[:children].each_with_index do |ao_uri, i|
      child_ao = ArchivalObject.get_or_die(JSONModel(:archival_object).id_for(ao_uri))
      child_ao.update_position_only(nil, start_index + i)
    end

    updated_response(resource)
  end

end
