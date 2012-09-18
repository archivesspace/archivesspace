require_relative 'name_mixin'

class NamePerson < Sequel::Model(:name_person)
  include ASModel
  plugin :validation_helpers
  include NameMixin
end
