class ContainerLocation < Sequel::Model(:container_locations)
  include ASModel

  plugin :validation_helpers

  many_to_one :location

  jsonmodel_hint(:the_property => :location,
                 :is_array => false,
                 :contains_records_of_type => :location,
                 :corresponding_to_association => :location)

end