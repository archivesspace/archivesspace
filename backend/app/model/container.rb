class Container < Sequel::Model(:container)
  include ASModel

  set_model_scope :global
  plugin :validation_helpers

  one_to_many :container_location

  jsonmodel_hint(:the_property => :container_locations,
                 :contains_records_of_type => :container_location,
                 :corresponding_to_association  => :container_location,
                 :always_resolve => true)

end
