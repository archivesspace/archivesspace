class Location < Sequel::Model(:locations)
  include ASModel

  plugin :validation_helpers

end
