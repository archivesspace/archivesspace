class AgentContact < Sequel::Model(:agent_contacts)
  include ASModel
  plugin :validation_helpers
end
