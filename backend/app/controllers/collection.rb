class ArchivesSpaceService < Sinatra::Base

  Endpoint
    .method(:post)
    .uri('/repositories/:repo_id/collections')
    .params(["collection", JSONModel(:collection), "The collection to create (JSON)", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.create_from_json(params[:collection], :repo_id => params[:repo_id])

    created_response(collection[:id], params[:collection]._warnings)
  end


  Endpoint
    .method(:get)
    .uri('/repositories/:repo_id/collections/:collection_id')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    Collection.to_jsonmodel(params[:collection_id], :collection).to_json
  end


  Endpoint
    .method(:get)
    .uri('/repositories/:repo_id/collections/:collection_id/tree')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])

    tree = collection.tree

    if tree
      JSON(collection.tree)
    else
      raise NotFoundException.new("Tree doesn't exist")
    end
  end


  Endpoint
    .method(:post)
    .uri('/repositories/:repo_id/collections/:collection_id')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["collection", JSONModel(:collection), "The collection to create (JSON)", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])
    collection.update_from_json(params[:collection])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  Endpoint
    .method(:post)
    .uri('/repositories/:repo_id/collections/:collection_id/tree')
    .params(["collection_id", Integer, "The ID of the collection to retrieve"],
            ["tree", JSONModel(:collection_tree), "A JSON tree representing the modified hierarchy", :body => true],
            ["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    collection = Collection.get_or_die(params[:collection_id])
    collection.update_tree(params[:tree])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  Endpoint
    .method(:get)
    .uri('/repositories/:repo_id/collections')
    .params(["repo_id", Integer, "The repository ID"])
    .returns([200, "OK"]) \
  do
    JSON(Collection.filter({:repo_id => params[:repo_id]}).collect {|coll|
           Collection.to_jsonmodel(coll, :collection).to_hash})
  end

end
