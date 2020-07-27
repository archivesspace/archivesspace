class AgentRecordIdentifier < Sequel::Model(:agent_record_identifier)
  include ASModel
  include AgentSubrecords
  
  corresponds_to JSONModel(:agent_record_identifier)

  set_model_scope :global
  def validate
    validate_agent_defined
  end
end
