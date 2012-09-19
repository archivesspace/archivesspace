require_relative 'name_mixin'

class NameFamily < Sequel::Model(:name_family)
  include ASModel
  plugin :validation_helpers
  include NameMixin
end
