class Deaccession < Sequel::Model(:deaccessions)
  include ASModel
  include Extents
  include Dates

  plugin :validation_helpers

end
