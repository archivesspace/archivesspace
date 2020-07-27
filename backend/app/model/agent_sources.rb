class AgentSources < Sequel::Model(:agent_sources)
  include ASModel
  include AgentSubrecords

  corresponds_to JSONModel(:agent_sources)

  set_model_scope :global

  def validate
    validate_agent_defined
  end
end

