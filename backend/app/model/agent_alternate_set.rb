class AgentAlternateSet < Sequel::Model(:agent_alternate_set)
  include ASModel
  include AgentSubrecords

  corresponds_to JSONModel(:agent_alternate_set)

  set_model_scope :global

  def validate
    validate_agent_defined
  end 
end

