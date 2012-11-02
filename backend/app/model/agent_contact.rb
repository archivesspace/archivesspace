class AgentContact < Sequel::Model(:agent_contact)
  include ASModel
  plugin :validation_helpers
  set_model_scope :global
end
