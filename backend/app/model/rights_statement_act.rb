class RightsStatementAct < Sequel::Model(:rights_statement_act)
  include ASModel
  corresponds_to JSONModel(:rights_statement_act)

  include Notes

  set_model_scope :global
end
