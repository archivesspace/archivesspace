class Deaccession < Sequel::Model(:deaccession)
  include ASModel
  include Extents
  include Dates

  plugin :validation_helpers

end
