class ContainerLocation < Sequel::Model(:container_location)
  include ASModel


  set_model_scope :global
  corresponds_to JSONModel(:container_location)
  many_to_one :location

  def_nested_record(:the_property => :location,
                    :is_array => false,
                    :contains_records_of_type => :location,
                    :corresponding_to_association => :location)

  def validate
    if self.location_id and self.status === "previous"
      location = Location[self.location_id]
      errors.add("status", "cannot be previous if Location is not temporary") if location.temporary.nil?
    end

    super
  end

end
