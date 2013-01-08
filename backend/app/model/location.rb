class Location < Sequel::Model(:location)
  include ASModel
  include ExternalIDs

  set_model_scope :repository
  corresponds_to JSONModel(:location)
end
