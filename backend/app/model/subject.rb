class Subject < Sequel::Model(:subjects)
  plugin :validation_helpers
  include ASModel
end
