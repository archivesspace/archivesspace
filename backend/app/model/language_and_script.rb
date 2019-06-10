class LanguageAndScript < Sequel::Model(:language_and_script)
  include ASModel
  corresponds_to JSONModel(:language_and_script)

  set_model_scope :global
end
