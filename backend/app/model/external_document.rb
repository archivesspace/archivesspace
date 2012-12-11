class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
  set_model_scope :global
  corresponds_to JSONModel(:external_document)
end
