module LangDescriptions

  def self.included(base)
    require_relative '../language_and_script_of_description'

    base.one_to_many(:language_and_script_of_description)
    LanguageAndScriptOfDescription.many_to_one base.table_name

    base.def_nested_record(
      :the_property => :lang_descriptions,
      :contains_records_of_type => :language_and_script_of_description,
      :corresponding_to_association => :language_and_script_of_description
    )
  end

end
