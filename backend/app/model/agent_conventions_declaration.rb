class AgentConventionsDeclaration < Sequel::Model(:agent_conventions_declaration)
  include ASModel
  include AgentSubrecords

  corresponds_to JSONModel(:agent_conventions_declaration)

  set_model_scope :global
  
  def validate
    validate_agent_defined
  end
end

