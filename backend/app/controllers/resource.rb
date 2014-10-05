class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources')
    .description("Create a Resource")
    .params(["resource", JSONModel(:resource), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Resource, params[:resource])
  end


  Endpoint.get('/repositories/:repo_id/resources/:id')
    .description("Get a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    json = Resource.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/resources/:id/tree')
    .description("Get a Resource tree")
    .params(["id", :id],
            ["limit_to", String, "An Archival Object URI or 'root'", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:id])

    tree = if params[:limit_to] && !params[:limit_to].empty?
             if params[:limit_to] == "root"
               ao = :root
             else
               ref = JSONModel.parse_reference(params[:limit_to])

               if ref
                 ao = ArchivalObject[ref[:id]]
               else
                 raise BadParamsException.new(:limit_to => ["Invalid value"])
               end
             end

             resource.partial_tree(ao)
           else
             resource.tree
           end

    json_response(tree)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id')
    .description("Update a Resource")
    .params(["id", :id],
            ["resource", JSONModel(:resource), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Resource, params[:id], params[:resource])
  end


  Endpoint.get('/repositories/:repo_id/resources')
    .description("Get a list of Resources for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(Resource, params)
  end


  Endpoint.delete('/repositories/:repo_id/resources/:id')
    .description("Delete a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Resource, params[:id])
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/publish')
  .description("Publish a resource and all its sub-records and components")
  .params(["id", :id],
                     ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :updated],
           [400, :error]) \
  do
    resource = Resource.get_or_die(params[:id])
    resource.publish!

    updated_response(resource)
  end

end
