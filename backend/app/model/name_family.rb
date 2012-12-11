require_relative 'name_mixin'

class NameFamily < Sequel::Model(:name_family)
  include ASModel
  corresponds_to JSONModel(:name_family)
  include NameMixin
end
