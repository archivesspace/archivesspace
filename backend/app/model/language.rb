class Language < Sequel::Model(:language)
  include ASModel
  corresponds_to JSONModel(:language)

  set_model_scope :global
end
