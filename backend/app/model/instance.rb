class Instance < Sequel::Model(:instance)
  include ASModel
  include Representative
  corresponds_to JSONModel(:instance)

  set_model_scope :global

  one_to_many :sub_container

  def_nested_record(:the_property => :sub_container,
                    :is_array => false,
                    :contains_records_of_type => :sub_container,
                    :corresponding_to_association => :sub_container)

  define_relationship(:name => :instance_do_link,
                      :json_property => 'digital_object',
                      :contains_references_to_types => proc {[DigitalObject]},
                      :is_array => false)

  def representative_for_types
    { is_representative: [:resource, :archival_object] }
  end
end
