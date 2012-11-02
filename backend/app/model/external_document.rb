class ExternalDocument < Sequel::Model(:external_document)
  include ASModel
  set_model_scope :repository

  plugin :validation_helpers
end
