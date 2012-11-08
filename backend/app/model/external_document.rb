class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
  set_model_scope :global

  plugin :validation_helpers
end
