class ArchivesSpaceService < Sinatra::Base


  post '/archival_object' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer},
                   "archival_object" => {:doc => "The archival_object to create (JSON)", :type => JSONModel(:archival_object)},
                   "collection" => {:doc => "The collection containing this archival_object", :type => Integer, :optional => true},
                   "parent" => {:doc => "The archival_object that is parent of this one", :type => Integer, :optional => true}]

    repo = Repository[params[:repo_id]]
    id = repo.create_archival_object(params[:archival_object])

    if params["parent"] or params["collection"]
      collection = Collection[params["collection"]]

      if not collection
        raise NotFoundException("Collection not found")
      end

      collection.link(:parent => params["parent"],
                      :child => id)
    end

    created_response(id, params[:archival_object]._warnings)
  end


  get '/archival_object/:archival_object_id' do
    ensure_params ["archival_object_id" => {:doc => "The archival object ID", :type => Integer}]

    ao = ArchivalObject[params[:archival_object_id]]

    if ao
      JSONModel(:archival_object).from_sequel(ao).to_json
    else
      raise NotFoundException.new("Archival Object not found")
    end
  end


  get '/archival_object/:archival_object_id/children' do
    ensure_params ["archival_object_id" => {:doc => "The archival object ID", :type => Integer}]

    ao = ArchivalObject[params[:archival_object_id]]

    if not ao
      raise NotFoundException.new("Archival Object not found")
    end

    JSON(ao.children.map {|child| JSONModel(:archival_object).from_sequel(child).to_hash})
  end
  
  get '/archival_object' do
     ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer}]
     repo = Repository[params[:repo_id]]
     ArchivalObject.filter({:repo_id => repo.repo_id}).collect {|ao| ao.values}.to_json
  end

end
