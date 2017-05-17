class Instance < Sequel::Model(:instance)
  include ASModel
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


  def before_validation
    super

    self.is_representative = nil if self.is_representative != 1
  end


  def validate
    if is_representative
      validates_unique([:is_representative, :resource_id],
                       :message => "A resource can only have one representative instance")
      map_validation_to_json_property([:is_representative, :resource_id], :is_representative)

      validates_unique([:is_representative, :archival_object_id],
                       :message => "A archival_object can only have one representative instance")
      map_validation_to_json_property([:is_representative, :archival_object_id], :is_representative)
    end
  end



end
