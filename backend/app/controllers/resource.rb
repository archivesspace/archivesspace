class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources')
    .params(["resource", JSONModel(:resource), "The resource to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    resource = Resource.create_from_json(params[:resource], :repo_id => params[:repo_id])

    created_response(resource[:id], params[:resource]._warnings)
  end


  Endpoint.get('/repositories/:repo_id/resources/:resource_id')
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, "OK"]) \
  do
     json = Resource.to_jsonmodel(params[:resource_id], :resource)

     json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/resources/:resource_id/tree')
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:resource_id])

    tree = resource.tree

    if tree
      json_response(tree)
    else
      raise NotFoundException.new("Tree doesn't exist")
    end
  end


  Endpoint.post('/repositories/:repo_id/resources/:resource_id')
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["resource", JSONModel(:resource), "The resource to create", :body => true],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:resource_id])
    resource.update_from_json(params[:resource])

    json_response({:status => "Updated", :id => resource[:id]})
  end


  Endpoint.post('/repositories/:repo_id/resources/:resource_id/tree')
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["tree", JSONModel(:resource_tree), "A JSON tree representing the modified hierarchy", :body => true],
            ["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:resource_id])
    resource.update_tree(params[:tree])

    json_response({:status => "Updated", :id => resource[:id]})
  end


  Endpoint.get('/repositories/:repo_id/resources')
    .params(["repo_id", :repo_id])
    .returns([200, "OK"]) \
  do
    json_response(Resource.filter({:repo_id => params[:repo_id]}).collect {|coll|
                    Resource.to_jsonmodel(coll, :resource).to_hash})
  end

end
