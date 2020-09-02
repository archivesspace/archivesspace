class AgentMaintenanceHistory < Sequel::Model(:agent_maintenance_history)
  include ASModel
  
  corresponds_to JSONModel(:agent_maintenance_history)

  set_model_scope :global
end

