class ArchivesSpaceService < Sinatra::Base

  post '/collection' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer},
                   "collection" => {:doc => "The collection to create (JSON)", :type => JSONModel(:collection)}]

    repo = Repository[params[:repo_id]]
    id = repo.create_collection(params[:collection])

    created_response(id, params[:collection]._warnings)
  end


  get '/collection/:collection_id' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    JSONModel(:collection).from_sequel(collection).to_json
  end


  get '/collection/:collection_id/tree' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    JSON(collection.tree)
  end


  post '/collection/:collection_id' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer},
                   "collection" => {:doc => "The collection data to update (JSON)", :type => JSONModel(:collection)}]

    collection = Collection[params[:collection_id]]

    if collection
      collection.update(params[:collection].to_hash)
    else
      raise NotFoundException.new("Collection not found")
    end

    json_response({:status => "Updated", :id => collection[:id]})
  end
  
  post '/collection/:collection_id' do
    ensure_params ["collection_id" => {:doc => "The ID of the collection to retrieve", :type => Integer}]

    collection = Collection[params[:collection_id]]

    if not collection
      raise NotFoundException.new("Couldn't find collection")
    end

    JSONModel(:collection).from_sequel(collection).to_json
  end

  get '/collection' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer}]
    repo = Repository[params[:repo_id]]
    Collection.filter({:repo_id =>repo.repo_id}).collect {|acc| acc.values}.to_json
  end

end
