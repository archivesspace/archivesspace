class ArchivesSpaceService < Sinatra::Base

  post '/collection' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer},
                   "collection" => {:doc => "The collection to create (JSON)"}]

    collection = JSONModel(:collection).from_json(params[:collection])

    repo = Repository[params[:repo_id]]
    id = repo.create_collection(collection)

    json_response({:status => "Created", :id => id})
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

end
