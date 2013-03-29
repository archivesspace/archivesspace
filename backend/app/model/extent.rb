class Extent < Sequel::Model(:extent)
  include ASModel
  corresponds_to JSONModel(:extent)

  set_model_scope :global
end
