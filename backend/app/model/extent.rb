class Extent < Sequel::Model(:extent)
  include ASModel
  set_model_scope :global
  corresponds_to JSONModel(:extent)
end
