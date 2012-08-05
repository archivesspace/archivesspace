class ArchivesSpaceService < Sinatra::Base

  post '/repositories/:repo_id/collections' do
    ensure_params ["collection" => {
                     :doc => "The collection to create (JSON)",
                     :type => JSONModel(:collection),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    collection = Collection.create_from_json(params[:collection], :repo_id => params[:repo_id])

    created_response(collection[:id], params[:collection]._warnings)
  end


  get '/repositories/:repo_id/collections/:collection_id' do
    ensure_params ["collection_id" => {
                     :doc => "The ID of the collection to retrieve",
                     :type => Integer
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    Collection.to_jsonmodel(params[:collection_id], :collection).to_json
  end


  get '/repositories/:repo_id/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {
                     :doc => "The ID of the collection to retrieve",
                     :type => Integer
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    collection = Collection.get_or_die(params[:collection_id])

    tree = collection.tree

    if tree
      JSON(collection.tree)
    else
      raise NotFoundException.new("Tree doesn't exist")
    end
  end


  post '/repositories/:repo_id/collections/:collection_id' do
    ensure_params ["collection_id" => {
                     :doc => "The ID of the collection to retrieve",
                     :type => Integer
                   },
                   "collection" => {
                     :doc => "The collection to create (JSON)",
                     :type => JSONModel(:collection),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    collection = Collection.get_or_die(params[:collection_id])
    collection.update_from_json(params[:collection])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  post '/repositories/:repo_id/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {
                     :doc => "The ID of the collection to retrieve",
                     :type => Integer
                   },
                   "tree" => {
                     :doc => "A JSON tree representing the modified hierarchy",
                     :type => JSONModel(:collection_tree),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    collection = Collection.get_or_die(params[:collection_id])
    collection.update_tree(params[:tree])

    json_response({:status => "Updated", :id => collection[:id]})
  end


  get '/repositories/:repo_id/collections' do
    ensure_params ["repo_id" => {
                     :doc => "The ID of the repository containing the archival object",
                     :type => Integer
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    Collection.filter({:repo_id => params[:repo_id]}).collect {|acc| acc.values}.to_json
  end

end
