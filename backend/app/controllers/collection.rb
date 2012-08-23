class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/collections')
    .params(["collection", JSONModel(:collection), "The collection to create", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.create_from_json(params[:collection], :repo_id => params[:repo_id])

    created_response(collection[:id], params[:collection]._warnings)
  end


  Endpoint.get('/repositories/:repo_id/collections/:collection_id')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["repo_id", Integer, "The repository ID"],
            ["resolve", [String], "A list of references to resolve and embed in the response",
             :optional => true])
    .returns([200, "OK"]) \
  do
     json = Collection.to_jsonmodel(params[:collection_id], :collection)

     json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/collections/:collection_id/tree')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])

    tree = collection.tree

    if tree
      json_response(tree)
    else
      raise NotFoundException.new("Tree doesn't exist")
    end
  end


  Endpoint.post('/repositories/:repo_id/collections/:collection_id')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["collection", JSONModel(:collection), "The collection to create", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])
    collection.update_from_json(params[:collection])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  Endpoint.post('/repositories/:repo_id/collections/:collection_id/tree')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["tree", JSONModel(:collection_tree), "A JSON tree representing the modified hierarchy", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])
    collection.update_tree(params[:tree])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  Endpoint.get('/repositories/:repo_id/collections')
    .params(["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    json_response(Collection.filter({:repo_id => params[:repo_id]}).collect {|coll|
                    Collection.to_jsonmodel(coll, :collection).to_hash})
  end

end
