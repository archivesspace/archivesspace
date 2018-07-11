class LocationFunction < Sequel::Model(:location_function)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:location_function)

end
