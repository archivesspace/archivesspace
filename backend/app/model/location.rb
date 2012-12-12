class Location < Sequel::Model(:location)
  include ASModel

  set_model_scope :repository
  corresponds_to JSONModel(:location)
end
