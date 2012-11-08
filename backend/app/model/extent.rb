class Extent < Sequel::Model(:extent)
  include ASModel
  set_model_scope :global

  plugin :validation_helpers
end
