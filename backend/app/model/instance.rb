class Instance < Sequel::Model(:instances)
  include ASModel

  plugin :validation_helpers

  one_to_one :container

  jsonmodel_hint(:the_property => :container,
                 :contains_records_of_type => :container,
                 :corresponding_to_association => :container,
                 :always_resolve => true)
end