class ExternalDocument < Sequel::Model(:external_documents)
  include ASModel

  plugin :validation_helpers
end
