class ASDate < Sequel::Model(:date)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:date)
end
