class ContainerLocation < Sequel::Model(:container_location)

  include ASModel
  corresponds_to JSONModel(:container_location)

end
