require 'record_inheritance'

require_relative 'indexer_common'
require_relative 'periodic_indexer'

require 'set'

module PUIIndexerMixin

  PUI_RESOLVES = [
    'ancestors',
    'ancestors::linked_agents',
    'ancestors::subjects',
    'ancestors::instances::sub_container::top_container'
  ]

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

    add_batch_hook do |batch|

      resources = Set.new

      batch.each do |rec|
        if rec['primary_type'] == 'archival_object'
          resources << rec['resource']
        elsif rec['primary_type'] == 'resource'
          resources << rec['uri']
        end
      end

      add_infscroll_docs(resources, batch)
      add_largetree_docs(resources, batch)
    end
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
  #
  # FIXME: Doing things one at a time is probably going to be way too slow.
  def add_largetree_docs(resource_uris, batch)
    resource_uris.each do |resource_uri|
      json = JSONModel::HTTP.get_json(resource_uri + '/tree/root')

      # FIXME: need to arrange for these records to be deleted when their parent collection is

      # :ADD, "#{resource_uri}/tree/root"
      require 'pp';$stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [pui_indexer.rb:89 a1b22e]: " + {%Q^:ADD^ => :ADD, %Q^"#{resource_uri}/tree/root"^ => "#{resource_uri}/tree/root"}.pretty_inspect + "\n")

      batch << {
        'id' => "#{resource_uri}/tree/root",
        'publish' => "true",
        'primary_type' => "tree_root",
        'json' => ASUtils.to_json(json)
      }

      add_waypoints(json, resource_uri, nil, batch)

      # json
      require 'pp';$stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [pui_indexer.rb:91 be7580]: " + {%Q^json^ => json}.pretty_inspect + "\n")
    end
  end

  def add_waypoints(json, resource_uri, parent_uri, batch)
    json.fetch('waypoints').times do |waypoint_number|
      json = JSONModel::HTTP.get_json(resource_uri + '/tree/waypoint',
                                     :offset => waypoint_number,
                                     :parent_node => parent_uri)


      # :ADD, "#{resource_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}"
      require 'pp';$stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [pui_indexer.rb:113 2a1c6]: " + {%Q^:ADD^ => :ADD, %Q^"#{resource_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}"^ => "#{resource_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}"}.pretty_inspect + "\n")

      batch << {
        'id' => "#{resource_uri}/tree/waypoint_#{parent_uri}_#{waypoint_number}",
        'publish' => "true",
        'primary_type' => "tree_waypoint",
        'json' => ASUtils.to_json(json)
      }

      json.each do |waypoint_record|
        add_nodes(resource_uri, waypoint_record, batch)
      end

    end
  end

  def add_nodes(resource_uri, waypoint_record, batch)
    record_uri = waypoint_record.fetch('uri')

    # Index the path from this record back to the resource root
    node_id = JSONModel.parse_reference(record_uri).fetch(:id)
    path_json = JSONModel::HTTP.get_json(resource_uri + '/tree/node_from_root',
                                         :node_id => node_id)

    batch << {
      'id' => "#{resource_uri}/tree/node_from_root_#{node_id}",
      'publish' => "true",
      'primary_type' => "tree_node_from_root",
      'json' => ASUtils.to_json(path_json)
    }


    # Index the node itself if it has children
    if waypoint_record.fetch('child_count') > 0
      json = JSONModel::HTTP.get_json(resource_uri + '/tree/node',
                                      :node_uri => record_uri)

      # :ADD, "#{resource_uri}/tree/node_#{json.fetch('uri')}"
      require 'pp';$stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [pui_indexer.rb:136 af5d5b]: " + {%Q^:ADD^ => :ADD, %Q^"#{resource_uri}/tree/node_#{json.fetch('uri')}"^ => "#{resource_uri}/tree/node_#{json.fetch('uri')}"}.pretty_inspect + "\n")

      batch << {
        'id' => "#{resource_uri}/tree/node_#{json.fetch('uri')}",
        'publish' => "true",
        'primary_type' => "tree_node",
        'json' => ASUtils.to_json(json)
      }

      # Finally, walk the node's waypoints and index those too.
      add_waypoints(json, resource_uri, json.fetch('uri'), batch)
    end
  end

  def skip_index_record?(record)
    !record['record']['publish']
  end


  def skip_index_doc?(doc)
    !doc['publish']
  end
end

class PUIIndexerTask < PeriodicIndexerTask
  def initialize(params)
    super
    @worker_class = PUIIndexerWorker
  end
end

class PUIIndexerWorker < PeriodicIndexerWorker
  include PUIIndexerMixin

  def fetch_records(type, ids, resolve)
    records = JSONModel(type).all(:id_set => ids.join(","), 'resolve[]' => resolve)
    if RecordInheritance.has_type?(type)
      RecordInheritance.merge(records, :direct_only => true)
    else
      records
    end
  end

end

class PUIIndexer < PeriodicIndexer
  include PUIIndexerMixin

  def initialize(state = nil, name)
    index_state = state || IndexState.new(File.join(AppConfig[:data_directory], "indexer_pui_state"))

    super(index_state, name)

    # Set up our JSON schemas now that we know the JSONModels have been loaded
    RecordInheritance.prepare_schemas

    @time_to_sleep = AppConfig[:pui_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:pui_indexer_thread_count].to_i
    @records_per_thread = AppConfig[:pui_indexer_records_per_thread].to_i

    @task_class = PUIIndexerTask
  end

  def self.get_indexer(state = nil, name = "PUI Indexer")
    indexer = self.new(state, name)
  end
end
