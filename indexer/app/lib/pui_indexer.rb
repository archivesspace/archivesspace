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

  def initialize(state = nil, name)
    index_state = state || IndexState.new(File.join(AppConfig[:data_directory], "indexer_pui_state"))

    super(index_state, name)

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

  def configure_doc_rules
    super

    add_document_prepare_hook {|doc, record|

      if doc['primary_type'] == 'archival_object'
        doc['id'] = "#{doc['id']}#pui"
        doc['types'] ||= []
        doc['types'] << 'pui'
        doc['types'] << 'pui_archival_object'
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

      # FIXME: need to arrange for these records to be deleted when their parent collection is
      batch << {
        'id' => "#{resource_uri}/ordered_records",
        'publish' => "true",
        'primary_type' => "resource_ordered_records",
        'json' => ASUtils.to_json(json)
      }
    end
  end

  # FIXME: Need to do digital objects and classifications here too
  class LargeTreeDocIndexer

    attr_reader :batch

    def initialize(batch)
      # We'll track the nodes we find as we need to index their path from root
      # in a relatively efficient way
      @node_uris = []

      @batch = batch
    end

    def add_largetree_docs(resource_uris)
      resource_uris.each do |resource_uri|
        @node_uris.clear

        json = JSONModel::HTTP.get_json(resource_uri + '/tree/root')

        # FIXME: need to arrange for these records to be deleted when their parent collection is

        batch << {
          'id' => "#{resource_uri}/tree/root",
          'publish' => "true",
          'primary_type' => "tree_root",
          'json' => ASUtils.to_json(json)
        }

        add_waypoints(json, resource_uri, nil)

        index_paths_to_root(resource_uri, @node_uris)
      end
    end

    def add_waypoints(json, resource_uri, parent_uri)
      json.fetch('waypoints').times do |waypoint_number|
        json = JSONModel::HTTP.get_json(resource_uri + '/tree/waypoint',
                                        :offset => waypoint_number,
                                        :parent_node => parent_uri)


        batch << {
          'id' => "#{resource_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}",
          'publish' => "true",
          'primary_type' => "tree_waypoint",
          'json' => ASUtils.to_json(json)
        }

        json.each do |waypoint_record|
          add_nodes(resource_uri, waypoint_record)
        end
      end
    end

    def add_nodes(resource_uri, waypoint_record)
      record_uri = waypoint_record.fetch('uri')

      @node_uris << record_uri

      # Index the node itself if it has children
      if waypoint_record.fetch('child_count') > 0
        json = JSONModel::HTTP.get_json(resource_uri + '/tree/node',
                                        :node_uri => record_uri)

        batch << {
          'id' => "#{resource_uri}/tree/node_#{json.fetch('uri')}",
          'publish' => "true",
          'primary_type' => "tree_node",
          'json' => ASUtils.to_json(json)
        }

        # Finally, walk the node's waypoints and index those too.
        add_waypoints(json, resource_uri, json.fetch('uri'))
      end
    end

    def index_paths_to_root(root_uri, node_uris)
      node_uris
        .map {|uri| JSONModel.parse_reference(uri).fetch(:id)}
        .each_slice(128) do |node_ids|

        node_paths = JSONModel::HTTP.get_json(root_uri + '/tree/node_from_root',
                                              'node_ids[]' => node_ids)

        node_paths.each do |node_id, path|
          batch << {
            'id' => "#{root_uri}/tree/node_from_root_#{node_id}",
            'publish' => "true",
            'primary_type' => "tree_node_from_root",
            'json' => ASUtils.to_json(path)
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

    last_resource_mtime = [@state.get_last_mtime(repository.id, :resource) - @window_seconds, 0].max
    last_ao_mtime = [@state.get_last_mtime(repository.id, :archival_object) - @window_seconds, 0].max

    resource_ids = Set.new(JSONModel::HTTP.get_json(JSONModel(:resource).uri_for, :all_ids => true, :modified_since => last_resource_mtime))
    ao_ids = JSONModel::HTTP.get_json(JSONModel(:archival_object).uri_for, :all_ids => true, :modified_since => last_ao_mtime, :bollocks => 'true')

    ao_ids.each_slice(@records_per_thread) do |ids|
      archival_objects = JSONModel(:archival_object).all(:id_set => ids.join(","), 'resolve[]' => [])

      archival_objects.each do |ao|
        resource_ids << JSONModel.parse_reference(ao['resource']['ref']).fetch(:id)
      end
    end

    resource_uris = resource_ids.map {|id| JSONModel(:resource).uri_for(id)}

    batch = IndexBatch.new
    add_infscroll_docs(resource_uris, batch)

    LargeTreeDocIndexer.new(batch).add_largetree_docs(resource_uris)

    puts "Indexed #{batch.length} additional PUI records"

    index_batch(batch)
  end

end
