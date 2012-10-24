class Instance < Sequel::Model(:instance)
  include ASModel

  plugin :validation_helpers

  one_to_many :container

  jsonmodel_hint(:the_property => :container,
                 :is_array => false,
                 :contains_records_of_type => :container,
                 :corresponding_to_association => :container,
                 :always_resolve => true)

end
