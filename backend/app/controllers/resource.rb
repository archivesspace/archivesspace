require_relative 'tree_docs'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/resources')
    .description("Create a Resource")
    .params(["resource", JSONModel(:resource), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Resource, params[:resource])
  end


  Endpoint.get('/repositories/:repo_id/resources/:id')
    .description("Get a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    json = Resource.to_jsonmodel(params[:id])
    ark = ArkName.first(:resource_id => params[:id])
    json["ark_name"] = ArkName.to_jsonmodel(ark[:id]) unless ark.nil?

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/resources/:id/tree')
    .description("Get a Resource tree")
    .deprecated("Call the */tree/{root,waypoint,node} endpoints to traverse record trees." +
               "  See backend/app/model/large_tree.rb for further information.")
    .params(["id", :id],
            ["limit_to", String, "An Archival Object URI or 'root'", :optional => true],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:id])

    tree = if params[:limit_to] && !params[:limit_to].empty?
             if params[:limit_to] == "root"
               ao = :root
             else
               ref = JSONModel.parse_reference(params[:limit_to])

               if ref
                 ao = ArchivalObject[ref[:id]]
               else
                 raise BadParamsException.new(:limit_to => ["Invalid value"])
               end
             end

             resource.partial_tree(ao)
           else
             resource.tree
           end

    json_response(tree)
  end


  Endpoint.get('/repositories/:repo_id/resources/:id/ordered_records')
    .description("Get the list of URIs of this published resource and all published archival objects contained within." +
                 "Ordered by tree order (i.e. if you fully expanded the record tree and read from top to bottom)")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "JSONModel(:resource_ordered_records)"]) \
  do
    resource = Resource.get_or_die(params[:id])

    json_response(JSONModel(:resource_ordered_records).from_hash({:uris => resource.ordered_records}, raise_errors = true, trusted = true))
  end


  Endpoint.get('/repositories/:repo_id/resources/:id/top_containers')
    .description("Get Top Containers linked to a published resource and published archival ojbects contained within.")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "a list of linked top containers"],
             [404, "Not found"]) \
  do
    resource = Resource.get_or_die(params[:id])
    top_container = []
    records = resource.ordered_records.map {|record| record = record['ref']}

    records.each do |record|
      ref = JSONModel.parse_reference(record)
      case ref[:type]
      when "resource"
        obj = Resource.to_jsonmodel(ref[:id])
      else
        obj = ArchivalObject.to_jsonmodel(ref[:id])
      end
      top_container.push(obj[:instances].map {|instance|
                    instance['instance_type'] == 'digital_object' ? nil :
                    instance['sub_container']['top_container']
                  }.compact)

    end

    json_response(top_container.uniq.flatten)

  end


  Endpoint.post('/repositories/:repo_id/resources/:id')
    .description("Update a Resource")
    .params(["id", :id],
            ["resource", JSONModel(:resource), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Resource, params[:id], params[:resource])
  end


  Endpoint.get('/repositories/:repo_id/resources')
    .description("Get a list of Resources for a Repository")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(Resource, params)
  end


  Endpoint.delete('/repositories/:repo_id/resources/:id')
    .description("Delete a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Resource, params[:id])
  end


  Endpoint.post('/repositories/:repo_id/resources/:id/publish')
  .description("Publish a resource and all its sub-records and components")
  .params(["id", :id],
                     ["repo_id", :repo_id])
  .permissions([:update_resource_record])
  .returns([200, :updated],
           [400, :error]) \
  do
    resource = Resource.get_or_die(params[:id])
    resource.publish!

    updated_response(resource)
  end


  Endpoint.get('/repositories/:repo_id/resources/:id/models_in_graph')
    .description("Get a list of record types in the graph of a resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "OK"]) \
  do
    resource = Resource.get_or_die(params[:id])

    graph = resource.object_graph

    record_types = graph.models.map {|m| m.my_jsonmodel(true) }.compact.map {|j| j.record_type}.reject {|t| t == 'resource' }

    json_response(record_types)
  end

  ## Trees!

  Endpoint.get('/repositories/:repo_id/resources/:id/tree/root')
    .description("Fetch tree information for the top-level resource record")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::ROOT_DOCS]) \
  do
    json_response(large_tree_for_resource.root)
  end

  Endpoint.get('/repositories/:repo_id/resources/:id/tree/waypoint')
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

    json_response(large_tree_for_resource.waypoint(parent_id, offset))
  end

  Endpoint.get('/repositories/:repo_id/resources/:id/tree/node')
    .description("Fetch tree information for an Archival Object record within a tree")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_uri", String, "The URI of the Archival Object record of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_DOCS]) \
  do
    ao_id = JSONModel.parse_reference(params[:node_uri]).fetch(:id)

    json_response(large_tree_for_resource.node(ArchivalObject.get_or_die(ao_id)))
  end

  Endpoint.get('/repositories/:repo_id/resources/:id/tree/node_from_root')
    .description("Fetch tree paths from the root record to Archival Objects")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["node_ids", [Integer], "The IDs of the Archival Object records of interest"],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_FROM_ROOT_DOCS]) \
  do
    json_response(large_tree_for_resource.node_from_root(params[:node_ids], params[:repo_id]))
  end

  private

  def large_tree_for_resource(largetree_opts = {})
    resource = Resource.get_or_die(params[:id])

    large_tree = LargeTree.new(resource, {:published_only => params[:published_only]}.merge(largetree_opts))
    large_tree.add_decorator(LargeTreeResource.new)

    large_tree
  end

end
