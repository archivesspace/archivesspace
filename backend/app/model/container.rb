class Container < Sequel::Model(:container)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:container)

  one_to_many :container_location

  def_nested_record(:the_property => :container_locations,
                    :contains_records_of_type => :container_location,
                    :corresponding_to_association  => :container_location,
                    :always_resolve => true)
end
