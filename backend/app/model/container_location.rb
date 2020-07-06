class ContainerLocation < Sequel::Model(:container_location)

  include ASModel
  corresponds_to JSONModel(:container_location)

  define_relationship(:name => :top_container_housed_at,
                      :contains_references_to_types => proc {[TopContainer, Location]}
                      )

end
