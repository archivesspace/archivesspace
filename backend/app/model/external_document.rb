class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
  corresponds_to JSONModel(:external_document)

  set_model_scope :global
end
