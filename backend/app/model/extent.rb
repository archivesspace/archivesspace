class Extent < Sequel::Model(:extents)
  include ASModel

  plugin :validation_helpers
end
