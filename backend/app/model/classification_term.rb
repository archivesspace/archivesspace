class ClassificationTerm < Sequel::Model(:classification_term)
  include ASModel
  include Relationships
  include Orderable

  corresponds_to JSONModel(:classification_term)
  set_model_scope(:repository)

  orderable_root_record_type :classification, :classification_term

  define_relationship(:name => :classification_creator,
                      :json_property => 'creator',
                      :contains_references_to_types => proc {
                        AgentManager.registered_agents.map {|a| a[:model]}
                      },
                      :is_array => false)
end
