require_relative 'relationships'

class Container < Sequel::Model(:container)
  include ASModel
  corresponds_to JSONModel(:container)

  include Relationships

  set_model_scope :global

  define_relationship(:name => :housed_at,
                      :json_property => 'container_locations',
                      :contains_references_to_types => proc {[Location]})


  def validate
    my_relationships(:housed_at).each_with_index do |(relationship_properties, related_location), idx|
      if relationship_properties[:status] === "previous" && !related_location.temporary
        errors.add("container_locations/#{idx}/status", "cannot be previous if Location is not temporary")
        break
      end
    end

    super
  end
end
