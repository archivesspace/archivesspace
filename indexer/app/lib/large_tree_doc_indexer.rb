class LargeTreeDocIndexer

  attr_reader :batch, :deletes

  def initialize(batch)
    # We'll track the nodes we find as we need to index their path from root
    # in a relatively efficient way
    @node_uris = []

    @batch = batch
    @deletes = []
  end

  def add_largetree_docs(root_record_uris)
    root_record_uris.each do |node_uri|
      @node_uris.clear

      json = JSONModel::HTTP.get_json(node_uri + '/tree/root',
                                      :published_only => true)

      batch << {
        'id' => "#{node_uri}/tree/root",
        'pui_parent_id' => node_uri,
        'publish' => "true",
        'primary_type' => "tree_root",
        'json' => ASUtils.to_json(json)
      }

      add_waypoints(json, node_uri, nil)

      index_paths_to_root(node_uri, @node_uris)
    end
  end

  def add_waypoints(json, root_record_uri, parent_uri)
    json.fetch('waypoints').times do |waypoint_number|
      json = JSONModel::HTTP.get_json(root_record_uri + '/tree/waypoint',
                                      :offset => waypoint_number,
                                      :parent_node => parent_uri,
                                      :published_only => true)


      batch << {
        'id' => "#{root_record_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}",
        'pui_parent_id' => (parent_uri || root_record_uri),
        'publish' => "true",
        'primary_type' => "tree_waypoint",
        'json' => ASUtils.to_json(json)
      }

      json.each do |waypoint_record|
        add_nodes(root_record_uri, waypoint_record)
      end
    end
  end

  def add_nodes(root_record_uri, waypoint_record)
    record_uri = waypoint_record.fetch('uri')

    @node_uris << record_uri

    # Index the node itself if it has children
    if waypoint_record.fetch('child_count') > 0
      json = JSONModel::HTTP.get_json(root_record_uri + '/tree/node',
                                      :node_uri => record_uri,
                                      :published_only => true)

      # We might bomb out if a record was deleted out from under us.
      return if json.nil?

      batch << {
        'id' => "#{root_record_uri}/tree/node_#{json.fetch('uri')}",
        'pui_parent_id' => json.fetch('uri'),
        'publish' => "true",
        'primary_type' => "tree_node",
        'json' => ASUtils.to_json(json)
      }

      # Finally, walk the node's waypoints and index those too.
      add_waypoints(json, root_record_uri, json.fetch('uri'))
    else
      # Fixing #ANW-731
      # This node has no published children but it might have previously
      # so we need to remember its node doc so our caller can delete it
      @deletes.push("#{root_record_uri}/tree/node_#{record_uri}")
    end
  end

  def index_paths_to_root(root_uri, node_uris)
    node_uris.each_slice(128) do |node_uris|

      node_id_to_uri = Hash[node_uris.map {|uri| [JSONModel.parse_reference(uri).fetch(:id), uri]}]
      node_paths = JSONModel::HTTP.get_json(root_uri + '/tree/node_from_root',
                                            'node_ids[]' => node_id_to_uri.keys,
                                            :published_only => true)

      node_paths.each do |node_id, path|
        batch << {
          'id' => "#{root_uri}/tree/node_from_root_#{node_id}",
          'pui_parent_id' => node_id_to_uri.fetch(Integer(node_id)),
          'publish' => "true",
          'primary_type' => "tree_node_from_root",
          'json' => ASUtils.to_json({node_id => path})
        }
      end
    end
  end

end
