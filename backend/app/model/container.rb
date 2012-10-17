class Container < Sequel::Model(:containers)
  include ASModel

  plugin :validation_helpers
end