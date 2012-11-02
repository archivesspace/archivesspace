class Extent < Sequel::Model(:extent)
  include ASModel
  set_model_scope :repository

  plugin :validation_helpers
end
