class Note < Sequel::Model(:note)
  include ASModel

  set_model_scope :global
end
