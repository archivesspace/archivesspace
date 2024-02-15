require 'record_inheritance'

require_relative 'periodic_indexer'
require_relative 'large_tree_doc_indexer'

require 'set'

class PUIIndexer < PeriodicIndexer

  PUI_RESOLVES = AppConfig[:record_inheritance_resolves]

  def initialize(backend = nil, state = nil, name)
    state_class = AppConfig[:index_state_class].constantize
    index_state = state || state_class.new("indexer_pui_state")

    super(backend, index_state, name)

    # Set up our JSON schemas now that we know the JSONModels have been loaded
    RecordInheritance.prepare_schemas

    @time_to_sleep = AppConfig[:pui_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:pui_indexer_thread_count].to_i
    @records_per_thread = AppConfig[:pui_indexer_records_per_thread].to_i

    @unpublished_records = java.util.Collections.synchronizedList(java.util.ArrayList.new)
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
        doc['pui_parent_id'] = parent_id
        doc['types'] ||= []
        doc['types'] << 'pui'
        doc['types'] << "pui_#{doc['primary_type']}"
        doc['types'] << 'pui_record'
        doc['types'] << 'pui_only'
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
        # we don't want container_profile or top_container notes indexed for the public either
        if record['record']['instances']
          record['record']['instances'].each do |instance|
            if instance['sub_container'] && instance['sub_container']['top_container']
              top_container = instance['sub_container']['top_container']
              if top_container['_resolved']
                top_container['_resolved'].delete('internal_note')
                if top_container['_resolved']['container_profile'] && top_container['_resolved']['container_profile']['_resolved']
                  top_container['_resolved']['container_profile']['_resolved'].delete('notes')
                end
              end
            end
          end
        end
        build_fullrecord(doc, record)
      end
    }
  end

  def build_fullrecord(doc, record)
    doc['fullrecord_published'] = IndexerCommon.extract_string_values(record['record'], :published_only)
  end

  def add_notes(doc, record)
    if record['record']['notes']
      doc['notes_published'] = IndexerCommon.extract_string_values(record['record']['notes'], :published_only)
    end
  end

  def add_infscroll_docs(resource_uris, batch)
    resource_uris.each do |resource_uri|
      json = JSONModel::HTTP.get_json(resource_uri + '/ordered_records')

      batch << {
        'id' => "#{resource_uri}/ordered_records",
        'uri' => "#{resource_uri}/ordered_records",
        'pui_parent_id' => resource_uri,
        'publish' => "true",
        'primary_type' => "resource_ordered_records",
        'types' => ['pui'],
        'json' => ASUtils.to_json(json)
      }
    end
  end

  def skip_index_record?(record)
    published = record['record']['publish']

    stage_unpublished_for_deletion("#{record['record']['uri']}#pui") unless published

    !published
  end


  def skip_index_doc?(doc)
    published = doc['publish']

    stage_unpublished_for_deletion(doc['id']) unless published

    !published
  end

  def index_round_complete(repository)
    # Index any trees in `repository`
    tree_types = [[:resource, :archival_object],
                  [:digital_object, :digital_object_component],
                  [:classification, :classification_term]]

    start = Time.now
    checkpoints = []
    update_mtimes = false

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

    tree_indexer = LargeTreeDocIndexer.new(batch)
    tree_indexer.add_largetree_docs(tree_uris)

    if batch.length > 0
      log "Indexed #{batch.length} additional PUI records in repository #{repository.repo_code}"

      index_batch(batch, nil, :parent_id_field => 'pui_parent_id')
      send_commit
      update_mtimes = true
    end

    if tree_indexer.deletes.length > 0
      tree_indexer.deletes.each_slice(100) do |deletes|
        delete_records(deletes, :parent_id_field => 'pui_parent_id')
      end
    end

    handle_deletes(:parent_id_field => 'pui_parent_id')

    # Delete any unpublished records and decendents
    delete_records(@unpublished_records, :parent_id_field => 'pui_parent_id')
    @unpublished_records.clear()

    checkpoints.each do |repository, type, start|
      @state.set_last_mtime(repository.id, type, start) if update_mtimes
    end

  end

  def stage_unpublished_for_deletion(doc_id)
    @unpublished_records.add(doc_id) if doc_id =~ /#pui$/
  end

  def repositories_updated_action(updated_repositories)

    updated_repositories.each do |repository|

      if !repository['record']['publish']

        # Delete PUI-only Solr documents in case this is the first index run after the repository has been unpublished
        req = Net::HTTP::Post.new("#{solr_url.path}/update")
        req['Content-Type'] = 'application/json'
        delete_request = {:delete => {'query' => "repository:\"#{repository['uri']}\" AND types:pui_only"}}
        req.body = delete_request.to_json
        response = do_http_request(solr_url, req)
        if response.code == '200'
          Log.info "Deleted PUI-only documents in private repository #{repository['record']['repo_code']}: #{response}"
        else
          Log.error "SolrIndexerError when deleting PUI-only records in private repository #{repository['record']['repo_code']}: #{response.body}"
        end

      end

    end

  end
  
end
