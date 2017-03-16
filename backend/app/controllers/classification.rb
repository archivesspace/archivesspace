require_relative 'tree_docs'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/classifications')
    .description("Create a Classification")
    .params(["classification", JSONModel(:classification), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Classification, params[:classification])
  end


  Endpoint.get('/repositories/:repo_id/classifications/:id')
    .description("Get a Classification")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:classification)"]) \
  do
    json = Classification.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/classifications/:id/tree')
    .description("Get a Classification tree")
    .deprecated("Call the */tree/{root,waypoint,node} endpoints to traverse record trees." +
               "  See backend/app/model/large_tree.rb for further information.")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    classification = Classification.get_or_die(params[:id])

    json_response(classification.tree)
  end


  Endpoint.post('/repositories/:repo_id/classifications/:id')
    .description("Update a Classification")
    .params(["id", :id],
            ["classification", JSONModel(:classification), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_classification_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Classification, params[:id], params[:classification])
  end


  Endpoint.get('/repositories/:repo_id/classifications')
    .description("Get a list of Classifications for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:classification)]"]) \
  do
    handle_listing(Classification, params)
  end


  Endpoint.delete('/repositories/:repo_id/classifications/:id')
    .description("Delete a Classification")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_classification_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Classification, params[:id])
  end

  ## Trees!

  Endpoint.get('/repositories/:repo_id/classifications/:id/tree/root')
    .description("Fetch tree information for the top-level classification record")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::ROOT_DOCS]) \
  do
    json_response(large_tree_for_classification.root)
  end

  Endpoint.get('/repositories/:repo_id/classifications/:id/tree/waypoint')
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

    json_response(large_tree_for_classification.waypoint(parent_id, offset))
  end

  Endpoint.get('/repositories/:repo_id/classifications/:id/tree/node')
    .description("Fetch tree information for an Classification Term record within a tree")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_uri", String, "The URI of the Classification Term record of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_DOCS]) \
  do
    classification_term_id = JSONModel.parse_reference(params[:node_uri]).fetch(:id)

    json_response(large_tree_for_classification.node(ClassificationTerm.get_or_die(classification_term_id)))
  end

  Endpoint.get('/repositories/:repo_id/classifications/:id/tree/node_from_root')
    .description("Fetch tree path from the root record to Classification Terms")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_ids", [Integer], "The IDs of the Classification Term records of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_FROM_ROOT_DOCS]) \
  do
    json_response(large_tree_for_classification.node_from_root(params[:node_ids], params[:repo_id]))
  end

  private

  def large_tree_for_classification(largetree_opts = {})
    classification = Classification.get_or_die(params[:id])

    large_tree = LargeTree.new(classification, {:published_only => params[:published_only]}.merge(largetree_opts))
    large_tree.add_decorator(LargeTreeClassification.new)

    large_tree
  end


end
