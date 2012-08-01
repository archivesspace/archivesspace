class ArchivesSpaceService < Sinatra::Base

  post '/collections' do
    ensure_params ["collection" => {
                     :doc => "The collection to create (JSON)",
                     :type => JSONModel(:collection),
                     :body => true
                   }]

    collection = Collection.create_from_json(params[:collection])

    created_response(collection[:id], params[:collection]._warnings)
  end


  get '/collections/:collection_id' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    Collection.to_jsonmodel(params[:collection_id], :collection).to_json
  end


  get '/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection.get_or_die(params[:collection_id])
    JSON(collection.tree)
  end


  post '/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer},
                   "tree" => {:doc => "A JSON tree representing the modified hierarchy"}]

    collection = Collection.get_or_die(params[:collection_id])
    tree = JSON(params[:tree])

    collection.update_tree(tree)
  end

  get '/collections' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer}]
    repo = Repository[params[:repo_id]]
    Collection.filter({:repo_id =>repo.repo_id}).collect {|acc| acc.values}.to_json
  end

end
