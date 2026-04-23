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
      tags = fetch_language_tags(node_uri)

      if tags.empty?
        # Records with no +lang_descriptions+ (classifications, legacy data)
        # get a single cached tree keyed by the unsuffixed URI.  PUI falls
        # back to this URI when it can't find a locale-specific doc.
        index_tree_for_language(node_uri, nil)
      else
        tags.each { |tag| index_tree_for_language(node_uri, tag) }
      end
    end
  end

  # Returns the +"<lang>_<script>"+ tags for every +lang_descriptions+ entry on
  # the root record.  Empty array for record types that don't declare any
  # (classifications) or for records whose JSON can't be fetched.
  def fetch_language_tags(node_uri)
    root_json = JSONModel::HTTP.get_json(node_uri)
    return [] unless root_json.is_a?(Hash)

    entries = root_json['lang_descriptions'] || []
    entries.map { |entry|
      lang   = entry['language']
      script = entry['script']
      (lang && script) ? "#{lang}_#{script}" : nil
    }.compact.uniq
  end

  def index_tree_for_language(node_uri, lang_tag)
    @node_uris.clear

    tree_opts = tree_opts_for(lang_tag)
    suffix    = suffix_for(lang_tag)

    json = JSONModel::HTTP.get_json(node_uri + '/tree/root', tree_opts)

    batch << {
      'id' => "#{node_uri}/tree/root#{suffix}",
      'uri' => "#{node_uri}/tree/root#{suffix}",
      'pui_parent_id' => node_uri,
      'publish' => "true",
      'primary_type' => "tree_root",
      'types' => ['pui'],
      'json' => ASUtils.to_json(json)
    }

    add_waypoints(json, node_uri, nil, lang_tag)

    index_paths_to_root(node_uri, @node_uris, lang_tag)
  end

  def add_waypoints(json, root_record_uri, parent_uri, lang_tag = nil)
    tree_opts = tree_opts_for(lang_tag)
    suffix    = suffix_for(lang_tag)

    json.fetch('waypoints').times do |waypoint_number|
      json = JSONModel::HTTP.get_json(root_record_uri + '/tree/waypoint',
                                      tree_opts.merge(:offset => waypoint_number,
                                                      :parent_node => parent_uri))


      batch << {
        'id' => "#{root_record_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}#{suffix}",
        'uri' => "#{root_record_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}#{suffix}",
        'pui_parent_id' => (parent_uri || root_record_uri),
        'publish' => "true",
        'primary_type' => "tree_waypoint",
        'types' => ['pui'],
        'json' => ASUtils.to_json(json)
      }

      json.each do |waypoint_record|
        add_nodes(root_record_uri, waypoint_record, lang_tag)
      end
    end
  end

  def add_nodes(root_record_uri, waypoint_record, lang_tag = nil)
    record_uri = waypoint_record.fetch('uri')

    @node_uris << record_uri

    tree_opts = tree_opts_for(lang_tag)
    suffix    = suffix_for(lang_tag)

    # Index the node itself if it has children
    if waypoint_record.fetch('child_count') > 0
      json = JSONModel::HTTP.get_json(root_record_uri + '/tree/node',
                                      tree_opts.merge(:node_uri => record_uri))

      # We might bomb out if a record was deleted out from under us.
      return if json.nil?

      batch << {
        'id' => "#{root_record_uri}/tree/node_#{json.fetch('uri')}#{suffix}",
        'uri' => "#{root_record_uri}/tree/node_#{json.fetch('uri')}#{suffix}",
        'pui_parent_id' => json.fetch('uri'),
        'publish' => "true",
        'primary_type' => "tree_node",
        'types' => ['pui'],
        'json' => ASUtils.to_json(json)
      }

      # Finally, walk the node's waypoints and index those too.
      add_waypoints(json, root_record_uri, json.fetch('uri'), lang_tag)
    else
      # Fixing #ANW-731
      # This node has no published children but it might have previously
      # so we need to remember its node doc so our caller can delete it
      @deletes.push("#{root_record_uri}/tree/node_#{record_uri}#{suffix}")
    end
  end

  def index_paths_to_root(root_uri, node_uris, lang_tag = nil)
    tree_opts = tree_opts_for(lang_tag)
    suffix    = suffix_for(lang_tag)

    node_uris.each_slice(128) do |node_uris|

      node_id_to_uri = Hash[node_uris.map {|uri| [JSONModel.parse_reference(uri).fetch(:id), uri]}]
      node_paths = JSONModel::HTTP.get_json(root_uri + '/tree/node_from_root',
                                            tree_opts.merge('node_ids[]' => node_id_to_uri.keys))

      node_paths.each do |node_id, path|
        batch << {
          'id' => "#{root_uri}/tree/node_from_root_#{node_id}#{suffix}",
          'uri' => "#{root_uri}/tree/node_from_root_#{node_id}#{suffix}",
          'pui_parent_id' => node_id_to_uri.fetch(Integer(node_id)),
          'publish' => "true",
          'primary_type' => "tree_node_from_root",
          'types' => ['pui'],
          'json' => ASUtils.to_json({node_id => path})
        }
      end
    end
  end

  private

  def tree_opts_for(lang_tag)
    opts = { :published_only => true }
    opts[:description_language] = lang_tag if lang_tag
    opts
  end

  def suffix_for(lang_tag)
    lang_tag ? "/#{lang_tag}" : ""
  end

end
