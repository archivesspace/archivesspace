class Instance < Sequel::Model(:instance)
  include ASModel
  corresponds_to JSONModel(:instance)

  include Relationships
  include SubContainers

  set_model_scope :global

  one_to_many :container

  def_nested_record(:the_property => :container,
                    :is_array => false,
                    :contains_records_of_type => :container,
                    :corresponding_to_association => :container)

  define_relationship(:name => :instance_do_link,
                      :json_property => 'digital_object',
                      :contains_references_to_types => proc {[DigitalObject]},
                      :is_array => false)


end
