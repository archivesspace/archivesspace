require_relative 'name_mixin'

class NamePerson < Sequel::Model(:name_person)
  include ASModel
  corresponds_to JSONModel(:name_person)
  include NameMixin
end
