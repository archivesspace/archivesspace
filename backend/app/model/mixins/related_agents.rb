require_relative 'directional_relationships'

module RelatedAgents
  extend JSONModel

  def self.included(base)
    base.include(DirectionalRelationships)

    base.define_directional_relationship(:name => :related_agents,
                                         :json_property => 'related_agents',
                                         :contains_references_to_types => proc {
                                           AgentManager.registered_agents.map {|a| a[:model]}
                                         },
                                         :class_callback => proc {|clz|
                                           clz.instance_eval do
                                             include DynamicEnums
                                             uses_enums({
                                                          :property => 'relator',
                                                          :uses_enum => %w[agent_relationship_associative_relator
                                                                           agent_relationship_earlierlater_relator
                                                                           agent_relationship_parentchild_relator
                                                                           agent_relationship_subordinatesuperior_relator
                                                                           agent_relationship_identity_relator
                                                                           agent_relationship_hierarchical_relator
                                                                           agent_relationship_temporal_relator
                                                                           agent_relationship_family_relator]
                                                        },
                                                        {
                                                          :property => 'specific_relator',
                                                          :uses_enum => 'agent_relationship_specific_relator'
                                                        })
                                           end
                                           RelatedAgents.set_up_date_record_handling(clz)
                                         })
  end


  # When saving/loading this relationship, link up and fetch a nested date
  # record to capture the dates.
  def self.set_up_date_record_handling(relationship_clz)
    relationship_clz.instance_eval do
      extend JSONModel
      one_to_one :relationship_date, :class => "StructuredDateLabel", :key => :related_agents_rlshp_id

      include ASModel::SequelHooks

      def self.create(values)
        date_values = values.delete('dates')
        obj = super

        if date_values
          date = StructuredDateLabel.create_from_json(JSONModel(:structured_date_label).from_hash(date_values))
          obj.relationship_date = date
          obj.save
        end

        obj
      end


      alias_method :delete_orig, :delete
      define_method(:delete) do
        relationship_date.delete if relationship_date
        delete_orig
      end


      alias_method :values_orig, :values
      define_method(:values) do
        result = values_orig

        if self.relationship_date
          result['dates'] = StructuredDateLabel.to_jsonmodel(self.relationship_date).to_hash
        end

        result
      end
    end
  end

end
