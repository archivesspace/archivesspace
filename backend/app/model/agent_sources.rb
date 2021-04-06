class AgentSources < Sequel::Model(:agent_sources)
  include ASModel

  corresponds_to JSONModel(:agent_sources)

  set_model_scope :global
end
