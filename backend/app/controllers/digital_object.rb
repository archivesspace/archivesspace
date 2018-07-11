class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/digital_objects/:id')
    .description("Get a Digital Object")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    json = DigitalObject.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.post('/repositories/:repo_id/digital_objects')
    .description("Create a Digital Object")
    .params(["digital_object", JSONModel(:digital_object), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(DigitalObject, params[:digital_object])
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id')
    .description("Update a Digital Object")
    .params(["id", :id],
            ["digital_object", JSONModel(:digital_object), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_digital_object_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(DigitalObject, params[:id], params[:digital_object])
  end


  Endpoint.get('/repositories/:repo_id/digital_objects')
    .description("Get a list of Digital Objects for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:digital_object)]"]) \
  do
    handle_listing(DigitalObject, params)
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree')
    .description("Get a Digital Object tree")
    .deprecated("Call the */tree/{root,waypoint,node} endpoints to traverse record trees." +
               "  See backend/app/model/large_tree.rb for further information.")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    digital_object = DigitalObject.get_or_die(params[:id])

    json_response(digital_object.tree)
  end


  Endpoint.delete('/repositories/:repo_id/digital_objects/:id')
    .description("Delete a Digital Object")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(DigitalObject, params[:id])
  end


  Endpoint.post('/repositories/:repo_id/digital_objects/:id/publish')
  .description("Publish a digital object and all its sub-records and components")
  .params(["id", :id],
          ["repo_id", :repo_id])
  .permissions([:update_digital_object_record])
  .returns([200, :updated],
           [400, :error]) \
  do
    digital_object = DigitalObject.get_or_die(params[:id])
    digital_object.publish!

    updated_response(digital_object)
  end

  ## Trees!

  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree/root')
    .description("Fetch tree information for the top-level digital object record")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::ROOT_DOCS]) \
  do
    json_response(large_tree_for_digital_object.root)
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree/waypoint')
    .description("Fetch the record slice for a given tree waypoint")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["offset", Integer, "The page of records to return"],
            ["parent_node", String, "The URI of the parent of this waypoint (none for the root record)", :optional => true],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::WAYPOINT_DOCS]) \
  do
    offset = params[:offset]

    parent_id = if params[:parent_node]
                  JSONModel.parse_reference(params[:parent_node]).fetch(:id)
                else
                  # top-level record
                  nil
                end

    json_response(large_tree_for_digital_object.waypoint(parent_id, offset))
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree/node')
    .description("Fetch tree information for an Digital Object Component record within a tree")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_uri", String, "The URI of the Digital Object Component record of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_DOCS]) \
  do
    digital_object_component_id = JSONModel.parse_reference(params[:node_uri]).fetch(:id)

    json_response(large_tree_for_digital_object.node(DigitalObjectComponent.get_or_die(digital_object_component_id)))
  end

  Endpoint.get('/repositories/:repo_id/digital_objects/:id/tree/node_from_root')
    .description("Fetch tree paths from the root record to Digital Object Components")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_ids", [Integer], "The IDs of the Digital Object Component records of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_FROM_ROOT_DOCS]) \
  do
    json_response(large_tree_for_digital_object.node_from_root(params[:node_ids], params[:repo_id]))
  end

  private

  def large_tree_for_digital_object(largetree_opts = {})
    digital_object = DigitalObject.get_or_die(params[:id])

    large_tree = LargeTree.new(digital_object, {:published_only => params[:published_only]}.merge(largetree_opts))
    large_tree.add_decorator(LargeTreeDigitalObject.new)

    large_tree
  end

end
