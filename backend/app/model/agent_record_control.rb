class AgentRecordControl < Sequel::Model(:agent_record_control)
  include ASModel
  
  corresponds_to JSONModel(:agent_record_control)

  set_model_scope :global
end

