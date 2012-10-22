class Location < Sequel::Model(:location)
  include ASModel

  plugin :validation_helpers

end
