class NameFamily < Sequel::Model(:name_family)
  include ASModel
  plugin :validation_helpers
end
