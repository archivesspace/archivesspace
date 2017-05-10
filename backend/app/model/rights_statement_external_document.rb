class RightsStatementExternalDocument < ExternalDocument
  include ASModel

  corresponds_to JSONModel(:rights_statement_external_document)

  set_model_scope :global
end
