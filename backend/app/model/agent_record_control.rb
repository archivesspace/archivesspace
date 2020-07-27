class AgentRecordControl < Sequel::Model(:agent_record_control)
  include ASModel
  include AgentSubrecords
  
  corresponds_to JSONModel(:agent_record_control)

  set_model_scope :global

  # validations:
  # must be linked to one agent type

  def validate
    validate_agent_defined
    super
  end

  
end

