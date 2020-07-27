class AgentMaintenanceHistory < Sequel::Model(:agent_maintenance_history)
  include ASModel
  include AgentSubrecords
  
  corresponds_to JSONModel(:agent_maintenance_history)

  set_model_scope :global
  def validate
    validate_agent_defined
  end
end

