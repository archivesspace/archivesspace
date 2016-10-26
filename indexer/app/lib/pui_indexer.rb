require 'record_inheritance'

require_relative 'indexer_common'
require_relative 'periodic_indexer'

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
      doc['id'] = "#{doc['id']}#pui"
    }

    add_document_prepare_hook {|doc, record|
      doc['types'] = []
      doc['types'] << 'pui_record' if ['archival_object',
                                       'accession',
                                       'digital_object',
                                       'digital_object_component'].include?(doc['primary_type'])
      doc['types'] << 'pui_collection' if ['resource'].include?(doc['primary_type'])
      doc['types'] << 'pui_record_group' if ['classification'].include?(doc['primary_type'])
      doc['types'] << 'pui_person' if ['agent_person'].include?(doc['primary_type'])
      doc['types'] << 'pui_agent' if ['agent_person', 'agent_corporate_entity'].include?(doc['primary_type'])
      doc['types'] << 'pui_subject' if ['subject'].include?(doc['primary_type'])
    }


    # this runs after the hooks in indexer_common, so we can overwrite with confidence
    add_document_prepare_hook {|doc, record|
      if RecordInheritance.has_type?(doc['primary_type'])
        merged = RecordInheritance.merge(record['record'], :remove_ancestors => true)
        # special handling for json because we need to include indirectly inherited
        # fields too - the json sent to indexer_common only has directly inherited
        # fields because only they should be indexed.
        doc['json'] = ASUtils.to_json(merged)

        # special handling for title because it is populated from display_string
        # in indexer_common and display_string is not changed in the merge process
        doc['title'] = merged['title'] if merged['title']
      end
    }
    
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

    @time_to_sleep = AppConfig[:pui_indexing_frequency_seconds].to_i
    @thread_count = AppConfig[:pui_indexer_thread_count].to_i
    @records_per_thread = AppConfig[:pui_indexer_records_per_thread].to_i

    @task_class = PUIIndexerTask
  end

  def self.get_indexer(state = nil, name = "PUI Indexer")
    indexer = self.new(state, name)
  end
end
