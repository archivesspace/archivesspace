class ArchivesSpaceService < Sinatra::Base


  post '/repositories/:repo_id/archival_objects' do
    ensure_params ["archival_object" => {
                     :doc => "The archival_object to create (JSON)",
                     :type => JSONModel(:archival_object),
                     :body => true
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    ao = ArchivalObject.create_from_json(params[:archival_object],
                                         :repo_id => params[:repo_id])

    parent_id = params[:archival_object].get_reference_id("parent")
    collection_id = params[:archival_object].get_reference_id("collection")

    if parent_id or collection_id
      collection = Collection.get_or_die(collection_id)

      collection.link(:parent => parent_id,
                      :child => ao[:id])
    end

    created_response(ao[:id], params[:archival_object]._warnings)
  end


  post '/repositories/:repo_id/archival_objects/:archival_object_id' do
    ensure_params ["archival_object_id" => {
                     :doc => "The archival object ID to update",
                     :type => Integer},
                   "archival_object" => {
                     :doc => "The archival object data to update (JSON)",
                     :type => JSONModel(:archival_object),
                     :body => true}]

    ao = ArchivalObject[params[:archival_object_id]]

    if ao
      ao.update(params[:archival_object].to_hash)
    else
      raise NotFoundException.new("Archival Object not found")
    end

    json_response({:status => "Updated", :id => ao[:id]})
  end


  get '/repositories/:repo_id/archival_objects/:archival_object_id' do
    ensure_params ["archival_object_id" => {
                     :doc => "The archival object ID",
                     :type => Integer
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    ArchivalObject.to_jsonmodel(params[:archival_object_id], :archival_object).to_json
  end


  get '/repositories/:repo_id/archival_objects/:archival_object_id/children' do
    ensure_params ["archival_object_id" => {
                     :doc => "The archival object ID",
                     :type => Integer
                   },
                   "repo_id" => {
                     :doc => "The repository ID",
                     :type => Integer,
                   }]

    ao = ArchivalObject.get_or_die(params[:archival_object_id])
    JSON(ao.children.map {|child| ArchivalObject.to_jsonmodel(child, :archival_object).to_hash})
  end


  get '/repositories/:repo_id/archival_objects' do
    ensure_params ["repo_id" => {
                     :doc => "The ID of the repository containing the archival object",
                     :type => Integer
                   }]
     JSON(ArchivalObject.filter({:repo_id => params[:repo_id]}).
                         collect {|ao| ArchivalObject.to_jsonmodel(ao, :archival_object).to_hash})
  end

end
