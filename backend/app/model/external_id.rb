class ExternalId < Sequel::Model(:external_id)
  include ASModel
  corresponds_to JSONModel(:external_id)

  set_model_scope :global
end
