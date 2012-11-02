class Location < Sequel::Model(:location)
  include ASModel

  set_model_scope :repository
  plugin :validation_helpers

end
