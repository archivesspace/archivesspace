class AgentContact < Sequel::Model(:agent_contact)
  include ASModel
  set_model_scope :global
  corresponds_to JSONModel(:agent_contact)
end
