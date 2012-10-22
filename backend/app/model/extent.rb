class Extent < Sequel::Model(:extent)
  include ASModel

  plugin :validation_helpers
end
