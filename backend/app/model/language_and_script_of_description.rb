class LanguageAndScriptOfDescription < Sequel::Model(:language_and_script_of_description)
  include ASModel
  include Representative
  corresponds_to JSONModel(:language_and_script_of_description)
  set_model_scope :global

  def representative_for_types
    { is_primary: [:accession, :digital_object, :resource] }
  end
end
