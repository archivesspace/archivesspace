class WhoSaidHello < Sequel::Model(:whosaidhello)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:hello_world)

end
