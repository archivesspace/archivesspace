class AgentContact < Sequel::Model(:agent_contact)
  include ASModel
  corresponds_to JSONModel(:agent_contact)

  include Publishable
  include Telephones
  include Notes
  include Representative

  set_model_scope :global

  def representative_for_types
    { is_representative: [:agent_person, :agent_family, :agent_corporate_entity, :agent_software] }
  end
end
