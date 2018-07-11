class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources/:id/children')
  .description("Batch create several Archival Objects as children of an existing Resource")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the resource", :body => true],
          ["id", :id],
          ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    resource = Resource.get_or_die(params[:id])

    resource.add_children(params[:children])

    updated_response(resource)
  end


  Endpoint.post('/repositories/:repo_id/archival_objects/:id/children')
  .description("Batch create several Archival Objects as children of an existing Archival Object")
  .params(["children", JSONModel(:archival_record_children), "The children to add to the archival object", :body => true],
          ["id", Integer, "The ID of the archival object to add children to"],
          ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])

    ao.add_children(params[:children])

    updated_response(ao)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/children')
  .description("Batch create several Digital Object Components as children of an existing Digital Object")
  .params(["children", JSONModel(:digital_record_children), "The component children to add to the digital object", :body => true],
          ["id", :id],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    digital_object = DigitalObject.get_or_die(params[:id])

    digital_object.add_children(params[:children])

    updated_response(digital_object)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/children')
  .description("Batch create several Digital Object Components as children of an existing Digital Object Component")
  .params(["children", JSONModel(:digital_record_children), "The children to add to the digital object component", :body => true],
          ["id", Integer, "The ID of the digital object component to add children to"],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    doc = DigitalObjectComponent.get_or_die(params[:id])

    doc.add_children(params[:children])

    updated_response(doc)
  end

  Endpoint.post('/repositories/:repo_id/archival_objects/:id/accept_children')
  .description("Move existing Archival Objects to become children of an Archival Object")
  .params(["children", [String], "The children to move to the Archival Object", :optional => true],
          ["id", Integer, "The ID of the Archival Object to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(ArchivalObject, ArchivalObject)
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/accept_children')
  .description("Move existing Archival Objects to become children of a Resource")
  .params(["children", [String], "The children to move to the Resource", :optional => true],
          ["id", Integer, "The ID of the Resource to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(Resource, ArchivalObject)
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/accept_children')
  .description("Move existing Digital Object components to become children of a Digital Object")
  .params(["children", [String], "The children to move to the Digital Object", :optional => true],
          ["id", Integer, "The ID of the Digital Object to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(DigitalObject, DigitalObjectComponent)
  end


  Endpoint.post('/repositories/:repo_id/digital_object_components/:id/accept_children')
  .description("Move existing Digital Object Components to become children of a Digital Object Component")
  .params(["children", [String], "The children to move to the Digital Object Component", :optional => true],
          ["id", Integer, "The ID of the Digital Object Component to move children to"],
          ["position", Integer, "The index for the first child to be moved to"],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :created],
           [400, :error],
           [409, :error]) \
  do
    accept_children_response(DigitalObjectComponent, DigitalObjectComponent)
  end


  Endpoint.post('/repositories/:repo_id/classifications/:id/accept_children')
  .description("Move existing Classification Terms to become children of a Classification")
  .params(["children", [String], "The children to move to the Classification", :optional => true],
          ["id", Integer, "The ID of the Classification to move children to"],
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
  .description("Move existing Classification Terms to become children of another Classification Term")
  .params(["children", [String], "The children to move to the Classification Term", :optional => true],
          ["id", Integer, "The ID of the Classification Term to move children to"],
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

    unless params[:children].empty?
      position = params[:position]
      parent_id = (target_class == child_class) ? params[:id] : nil

      if target_class == child_class
        # If any of the children being dropped is an ancestor of the current node,
        # that's not OK.  No being your own grandfather!
        ancestor = target
        loop do
          break unless ancestor.parent_id

          ancestor = target_class.get_or_die(ancestor.parent_id)

          if params[:children].include?(ancestor.uri)
            raise ConflictException.new("Can't make a parent into its own child")
          end
        end
      end

      # This has been flipped.  Due to changes in the tree_nodes, the values should
      # be processed using the lowest to highest.  This reverses the previous process
      # Does this cause any undo problems?
      first_uri = params[:children][0]
      first_obj = child_class.get_or_die(child_class.my_jsonmodel.id_for(first_uri))

      # ok, we are keeping it in the same parent and moving down the list, we
      # need to reverse to make sure the placement happens correctly.
      # If the first_obj doesn't have a parent_id, that means it's at the top
      # of the food chain, so we can check if the target is a Tree, not a TreeNode. 
      # Otherwise, we are moving into another parent.
      if ( target.id == first_obj.parent_id || ( target.class.included_modules.include?(Trees) && first_obj.parent_id.nil? ) )  && first_obj.logical_position < position
        ordered = params[:children].each_with_index.to_a.reverse
      else
        ordered = params[:children].each_with_index
      end

      last_child = nil
      ordered.each do |uri, i|
        last_child = child_class.get_or_die(child_class.my_jsonmodel.id_for(uri))
        last_child.set_parent_and_position(parent_id, position + i)
      end
    end

    updated_response(target)
  end
end
