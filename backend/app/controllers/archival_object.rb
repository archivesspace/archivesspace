class ArchivesSpaceService < Sinatra::Base


  post '/archival_objects' do
    ensure_params ["archival_object" => {
                     :doc => "The archival_object to create (JSON)",
                     :type => JSONModel(:archival_object),
                     :body => true
                   }]

    ao = ArchivalObject.create_from_json(params[:archival_object])

    parent_id = params[:archival_object].get_reference_id("parent")
    collection_id = params[:archival_object].get_reference_id("collection")

    if parent_id or collection_id
      collection = Collection.get_or_die(collection_id)

      collection.link(:parent => parent_id,
                      :child => ao[:id])
    end

    created_response(ao[:id], params[:archival_object]._warnings)
  end

  post '/archival_object/:archival_object_id' do
    ensure_params ["archival_object_id" => {:doc => "The archival object ID to update", :type => Integer},
                   "archival_object" => {:doc => "The archival object data to update (JSON)", :type => JSONModel(:accession)}]

    ao = ArchivalObject[params[:archival_object_id]]

    if ao
      ao.update(params[:archival_object].to_hash)
    else
      raise NotFoundException.new("Archival Object not found")
    end

    json_response({:status => "Updated", :id => ao[:id]})
  end

  get '/archival_objects/:archival_object_id' do
    ensure_params ["archival_object_id" => {:doc => "The archival object ID", :type => Integer}]

    ArchivalObject.to_jsonmodel(params[:archival_object_id], :archival_object).to_json
  end


  get '/archival_objects/:archival_object_id/children' do
    ensure_params ["archival_object_id" => {:doc => "The archival object ID", :type => Integer}]

    ao = ArchivalObject.get_or_die(params[:archival_object_id])
    JSON(ao.children.map {|child| ArchivalObject.to_jsonmodel(child, :archival_object).to_hash})
  end


  get '/archival_objects' do
     ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer}]
     repo = Repository[params[:repo_id]]
     ArchivalObject.filter({:repo_id => repo.repo_id}).collect {|ao| ao.values}.to_json
  end

end
