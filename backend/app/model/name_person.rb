class NamePerson < Sequel::Model(:name_person)
  include ASModel
  plugin :validation_helpers
end
