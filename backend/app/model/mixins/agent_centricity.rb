
module AgentCentricity

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def sequel_to_jsonmodel(obj, opts = {})
      json = super

      # build a modified json object for contexts 
      # in which archival objects are listed under
      # the agent they link to (e.g., EAC exports)
      if opts[:agent_centric]
        related_resources = []

        linked_agent_relation = Resource.find_relationship(:linked_agents)
        linked_agent_relation.find_by_participant(obj).each do |relation|

          related_record = AgentCentricity.find_other_referent(relation)
          next unless related_record

          # it may be necessary to check user permissions here -- need
          # more clarity on how agent-centric views should work with
          # repository scoping
          RequestContext.open(:repo_id => related_record.repo_id) do
            related_resources << {
              :role => BackendEnumSource.values_for_ids(relation[:role_id])[relation[:role_id]],
              :record => related_record.class.to_jsonmodel(related_record, :skip_relationships => true) 
            }
          end
        end

        data = json.instance_variable_get(:@data)
        data['_related_records'] = related_resources
      end

      json
    end
  end


  # rewrite of AbstractRelationship.other_referent_than,
  # which doesn't seem quite right for the purpose here
  def self.find_other_referent(relation)
    [Resource, ArchivalObject, DigitalObject, DigitalObjectComponent].each do |model|
      relation.class.reference_columns_for(model).each do |column|
        if relation[column]
          return model.respond_to?(:any_repo) ? model.any_repo[relation[column]] : model[relation[column]]
        end
      end
    end

    nil
  end
end
