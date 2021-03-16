class UsedLanguage < Sequel::Model(:used_language)
  include ASModel
  include Notes
  
  corresponds_to JSONModel(:used_language)

  set_model_scope :global
end

