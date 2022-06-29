class AgentRecordIdentifier < Sequel::Model(:agent_record_identifier)
  include ASModel

  corresponds_to JSONModel(:agent_record_identifier)

  set_model_scope :global
end
