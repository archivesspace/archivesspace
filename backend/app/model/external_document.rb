class ExternalDocument < Sequel::Model(:external_document)
  include ASModel

  plugin :validation_helpers
end
