class AgentType < Sequel::Model(:agent_types)
  include ASModel

  plugin :validation_helpers

end
