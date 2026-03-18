class LanguageAndScriptOfDescription < Sequel::Model(:language_and_script_of_description)
  include ASModel
  corresponds_to JSONModel(:language_and_script_of_description)
  set_model_scope :global
end
