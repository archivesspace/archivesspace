class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources/:id/children')
  .description("Add children to a Resource")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the resource", :body => true],
          ["id", :id],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    resource = Resource.get_or_die(params[:id])

    resource.add_children(params[:children])

    updated_response(resource)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/children')
  .description("Add children to an Archival Object")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the archival object", :body => true],
          ["id", Integer, "The ID of the archival object to add children to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])

    ao.add_children(params[:children])

    updated_response(ao)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/accept_children')
  .description("Move existing archival objects to become children of an Archival Object")
  .params(["children", [String], "The children to move to the archival object", :optional => true],
          ["id", Integer, "The ID of the archival object to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(ArchivalObject, ArchivalObject)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/accept_children')
  .description("Move existing archival objects to become children of a Resource")
  .params(["children", [String], "The children to move to the resource", :optional => true],
          ["id", Integer, "The ID of the resource to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(Resource, ArchivalObject)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/accept_children')
  .description("Move existing digital object components to become children of a digital object")
  .params(["children", [String], "The children to move to the digital object", :optional => true],
          ["id", Integer, "The ID of the digital object to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(DigitalObject, DigitalObjectComponent)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/accept_children')
  .description("Move existing digital object components to become children of a digital object component")
  .params(["children", [String], "The children to move to the digital object component", :optional => true],
          ["id", Integer, "The ID of the digital object component to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_archival_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(DigitalObjectComponent, DigitalObjectComponent)
  end


  Endpoint.post('/repositories/:repo_id/classifications/:id/accept_children')
  .description("Move existing terms to become children of a classification")
  .params(["children", [String], "The children to move to the classification", :optional => true],
          ["id", Integer, "The ID of the classification to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_classification_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(Classification, ClassificationTerm)
  end


  Endpoint.post('/repositories/:repo_id/classification_terms/:id/accept_children')
  .description("Move existing terms to become children of another classification term")
  .params(["children", [String], "The children to move to the classification term", :optional => true],
          ["id", Integer, "The ID of the classification term to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_classification_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(ClassificationTerm, ClassificationTerm)
  end


  private

  def accept_children_response(target_class, child_class)
    target = target_class.get_or_die(params[:id])

    position = params[:position]
    parent_id = (target_class == child_class) ? params[:id] : nil


    params[:children].each_with_index do |uri, i|
      child = child_class.get_or_die(child_class.my_jsonmodel.id_for(uri))
      child.update_position_only(parent_id, position + i)
    end

    updated_response(target)
  end

end
