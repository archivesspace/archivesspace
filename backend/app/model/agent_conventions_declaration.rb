class AgentConventionsDeclaration < Sequel::Model(:agent_conventions_declaration)
  include ASModel

  corresponds_to JSONModel(:agent_conventions_declaration)

  set_model_scope :global
end
