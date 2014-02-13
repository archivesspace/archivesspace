class Container < Sequel::Model(:container)
  include ASModel
  corresponds_to JSONModel(:container)

  include Relationships

  set_model_scope :global


  def self.handle_delete(ids)
    # Containers are funny (but not "ha ha" funny) because they're nested
    # records, yet contain relationships with other records.  If we're deleting
    # one of these nested records, we need to clear its relationship as well.

    relationship_defn = find_relationship(:housed_at)
    relationships = relationship_defn.find_by_participant_ids(self, ids)

    relationship_defn.handle_delete(relationships.map(&:id))
    super
  end


  define_relationship(:name => :housed_at,
                      :json_property => 'container_locations',
                      :contains_references_to_types => proc {[Location]},
                      :class_callback => proc { |clz|
                        clz.instance_eval do
                          plugin :validation_helpers

                          define_method(:validate) do

                            if self[:status] === "previous" && !Location[self[:location_id]].temporary
                              errors.add("container_locations/#{self[:aspace_relationship_position]}/status",
                                         "cannot be previous if Location is not temporary")
                            end

                            super
                          end

                        end
                      })

end
