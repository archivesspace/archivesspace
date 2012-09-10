class PersonName < NameForm
#class PersonName < Sequel::Model(:person_names)
  include ASModel
  plugin :validation_helpers

end
