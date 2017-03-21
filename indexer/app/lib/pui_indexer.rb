require 'record_inheritance'

require_relative 'periodic_indexer'

require 'set'

class PUIIndexer < PeriodicIndexer

  PUI_RESOLVES = [
    'ancestors',
    'ancestors::linked_agents',
    'ancestors::subjects',
    'ancestors::instances::sub_container::top_container'
  ]

  def initialize(backend = nil, state = nil, name)
    index_state = state || IndexState.new(File.join(AppConfig[:data_directory], "indexer_pui_state"))

    super(backend, index_state, name)

    # Set up our JSON schemas now that we know the JSONModels have been loaded
    RecordInheritance.prepare_schemas

    @time_to_sleep = AppConfig[:pui_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:pui_indexer_thread_count].to_i
    @records_per_thread = AppConfig[:pui_indexer_records_per_thread].to_i
  end

  def fetch_records(type, ids, resolve)
    records = JSONModel(type).all(:id_set => ids.join(","), 'resolve[]' => resolve)
    if RecordInheritance.has_type?(type)
      RecordInheritance.merge(records, :direct_only => true)
    else
      records
    end
  end

  def self.get_indexer(state = nil, name = "PUI Indexer")
    indexer = self.new(state, name)
  end

  def resolved_attributes
    super + PUI_RESOLVES
  end

  def record_types
    # We only want to index the record types we're going to make separate
    # PUI-specific versions of...
    (super.select {|type| RecordInheritance.has_type?(type)} + [:archival_object]).uniq
  end

  def configure_doc_rules
    super

    record_has_children('resource')
    record_has_children('archival_object')
    record_has_children('digital_object')
    record_has_children('digital_object_component')
    record_has_children('classification')
    record_has_children('classification_term')


    add_document_prepare_hook {|doc, record|

      if RecordInheritance.has_type?(doc['primary_type'])
        parent_id = doc['id']
        doc['id'] = "#{parent_id}#pui"
        doc['parent_id'] = parent_id
        doc['types'] ||= []
        doc['types'] << 'pui'
        doc['types'] << "pui_#{doc['primary_type']}"
        doc['types'] << 'pui_record'
      end
    }

    # this runs after the hooks in indexer_common, so we can overwrite with confidence
    add_document_prepare_hook {|doc, record|
      if RecordInheritance.has_type?(doc['primary_type'])
        # special handling for json because we need to include indirectly inherited
        # fields too - the json sent to indexer_common only has directly inherited
        # fields because only they should be indexed.
        # so we remerge without the :direct_only flag, and we remove the ancestors
        doc['json'] = ASUtils.to_json(RecordInheritance.merge(record['record'],
                                                              :remove_ancestors => true))

        # special handling for title because it is populated from display_string
        # in indexer_common and display_string is not changed in the merge process
        doc['title'] = record['record']['title'] if record['record']['title']

        # special handling for fullrecord because we don't want the ancestors indexed.
        # we're now done with the ancestors, so we can just delete them from the record
        record['record'].delete('ancestors')
        doc['fullrecord'] = CommonIndexer.build_fullrecord(record)
      end
    }
  end

  def add_infscroll_docs(resource_uris, batch)
    resource_uris.each do |resource_uri|
      json = JSONModel::HTTP.get_json(resource_uri + '/ordered_records')

      batch << {
        'id' => "#{resource_uri}/ordered_records",
        'parent_id' => resource_uri,
        'publish' => "true",
        'primary_type' => "resource_ordered_records",
        'json' => ASUtils.to_json(json)
      }
    end
  end


  class LargeTreeDocIndexer

    attr_reader :batch

    def initialize(batch)
      # We'll track the nodes we find as we need to index their path from root
      # in a relatively efficient way
      @node_uris = []

      @batch = batch
    end

    def add_largetree_docs(root_record_uris)
      root_record_uris.each do |node_uri|
        @node_uris.clear

        json = JSONModel::HTTP.get_json(node_uri + '/tree/root',
                                        :published_only => true)

        batch << {
          'id' => "#{node_uri}/tree/root",
          'parent_id' => node_uri,
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
          'parent_id' => (parent_uri || root_record_uri),
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
          'parent_id' => json.fetch('uri'),
          'publish' => "true",
          'primary_type' => "tree_node",
          'json' => ASUtils.to_json(json)
        }

        # Finally, walk the node's waypoints and index those too.
        add_waypoints(json, root_record_uri, json.fetch('uri'))
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
            'parent_id' => node_id_to_uri.fetch(Integer(node_id)),
            'publish' => "true",
            'primary_type' => "tree_node_from_root",
            'json' => ASUtils.to_json({node_id => path})
          }
        end
      end
    end

  end


  def skip_index_record?(record)
    !record['record']['publish']
  end


  def skip_index_doc?(doc)
    !doc['publish']
  end

  def index_round_complete(repository)
    # Index any trees in `repository`
    tree_types = [[:resource, :archival_object],
                  [:digital_object, :digital_object_component],
                  [:classification, :classification_term]]

    start = Time.now
    checkpoints = []

    tree_uris = []

    tree_types.each do |pair|
      root_type = pair.first
      node_type = pair.last

      checkpoints << [repository, root_type, start]
      checkpoints << [repository, node_type, start]

      last_root_node_mtime = [@state.get_last_mtime(repository.id, root_type) - @window_seconds, 0].max
      last_node_mtime = [@state.get_last_mtime(repository.id, node_type) - @window_seconds, 0].max

      root_node_ids = Set.new(JSONModel::HTTP.get_json(JSONModel(root_type).uri_for, :all_ids => true, :modified_since => last_root_node_mtime))
      node_ids = JSONModel::HTTP.get_json(JSONModel(node_type).uri_for, :all_ids => true, :modified_since => last_node_mtime)

      node_ids.each_slice(@records_per_thread) do |ids|
        node_records = JSONModel(node_type).all(:id_set => ids.join(","), 'resolve[]' => [])

        node_records.each do |record|
          root_node_ids << JSONModel.parse_reference(record[root_type.to_s]['ref']).fetch(:id)
        end
      end

      tree_uris.concat(root_node_ids.map {|id| JSONModel(root_type).uri_for(id) })
    end

    batch = IndexBatch.new

    add_infscroll_docs(tree_uris.select {|uri| JSONModel.parse_reference(uri).fetch(:type) == 'resource'},
                       batch)

    LargeTreeDocIndexer.new(batch).add_largetree_docs(tree_uris)

    if batch.length > 0
      log "Indexed #{batch.length} additional PUI records in repository #{repository.repo_code}"

      index_batch(batch)
      send_commit
    end

    checkpoints.each do |repository, type, start|
      @state.set_last_mtime(repository.id, type, start)
    end

  end

end
