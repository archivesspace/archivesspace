class AgentOtherAgencyCodes < Sequel::Model(:agent_other_agency_codes)
  include ASModel
  include AgentSubrecords
  corresponds_to JSONModel(:agent_other_agency_codes)

  set_model_scope :global

  def validate
    validate_agent_defined
  end
end

