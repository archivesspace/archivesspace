class AgentOtherAgencyCodes < Sequel::Model(:agent_other_agency_codes)
  include ASModel
  corresponds_to JSONModel(:agent_other_agency_codes)

  set_model_scope :global
end

