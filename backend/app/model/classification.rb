class Classification < Sequel::Model(:classification)
  include ASModel
  include Relationships

  corresponds_to JSONModel(:classification)
  set_model_scope(:repository)

  define_relationship(:name => :classification_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)
end
