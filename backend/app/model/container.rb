class Container < Sequel::Model(:containers)
  include ASModel

  plugin :validation_helpers

  one_to_many :container_locations

  jsonmodel_hint(:the_property => :container_locations,
                      :contains_records_of_type => :container_location,
                      :corresponding_to_association  => :container_locations,
                      :always_resolve => true)

end