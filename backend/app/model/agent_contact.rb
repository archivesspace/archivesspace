class AgentContact < Sequel::Model(:agent_contact)
  include ASModel
  corresponds_to JSONModel(:agent_contact)

  include Publishable

  set_model_scope :global

end
