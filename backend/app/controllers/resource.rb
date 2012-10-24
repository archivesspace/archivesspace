class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources')
    .description("Create a Resource")
    .params(["resource", JSONModel(:resource), "The resource to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Resource, :resource)
  end


  Endpoint.get('/repositories/:repo_id/resources/:resource_id')
    .description("Get a Resource")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, "(:resource)"]) \
  do
    json = Resource.to_jsonmodel(params[:resource_id], :resource, params[:repo_id])

    json_response(resolve_references(json.to_hash, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/resources/:resource_id/tree')
    .description("Get a Resource tree")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:resource_id], params[:repo_id])

    tree = resource.tree

    if tree
      json_response(tree)
    else
      raise NotFoundException.new("Tree doesn't exist")
    end
  end


  Endpoint.post('/repositories/:repo_id/resources/:resource_id')
    .description("Update a Resource")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["resource", JSONModel(:resource), "The resource to update", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Resource, :resource_id, :resource)
  end


  Endpoint.post('/repositories/:repo_id/resources/:resource_id/tree')
    .description("Update a Resource tree")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["tree", JSONModel(:resource_tree), "A JSON tree representing the modified hierarchy", :body => true],
            ["repo_id", :repo_id])
    .returns([200, :updated]) \
  do
    resource = Resource.get_or_die(params[:resource_id], params[:repo_id])
    resource.update_tree(params[:tree])

    updated_response(resource, params[:tree])
  end


  Endpoint.get('/repositories/:repo_id/resources')
    .description("Get a list of Resources for a Repository")
    .params(["repo_id", :repo_id])
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(Resource, :resource, :repo_id => params[:repo_id])
  end

end
