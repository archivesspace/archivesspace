class ArchivesSpaceService < Sinatra::Base

  post '/collections' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer},
                   "collection" => {:doc => "The collection to create (JSON)", :type => JSONModel(:collection)}]

    repo = Repository[params[:repo_id]]
    id = repo.create_collection(params[:collection])

    created_response(id, params[:collection]._warnings)
  end


  get '/collections/:collection_id' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    JSONModel(:collection).from_sequel(collection).to_json
  end


  get '/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    JSON(collection.tree)
  end


  post '/collections/:collection_id/tree' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer},
                   "tree" => {:doc => "A JSON tree representing the modified hierarchy"}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    tree = JSON(params[:tree])

    collection.update_tree(tree)
  end

  get '/collections' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer}]
    repo = Repository[params[:repo_id]]
    Collection.filter({:repo_id =>repo.repo_id}).collect {|acc| acc.values}.to_json
  end

end
