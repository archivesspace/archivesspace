class AgentIdentifier < Sequel::Model(:agent_identifier)
  include ASModel

  corresponds_to JSONModel(:agent_identifier)

  set_model_scope :global
end
