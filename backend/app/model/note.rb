class Note < Sequel::Model(:note)
  include ASModel

  include Publishable

  set_model_scope :global
end
