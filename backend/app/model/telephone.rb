class Telephone < Sequel::Model(:telephone)
  include ASModel
  corresponds_to JSONModel(:telephone)
  set_model_scope :global
end
