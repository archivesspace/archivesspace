class LangMaterial < Sequel::Model(:lang_material)
  include ASModel
  corresponds_to JSONModel(:lang_material)

  include Notes

  set_model_scope :global

  one_to_many :language_and_script

  def_nested_record(:the_property => :language_and_script,
                    :is_array => false,
                    :contains_records_of_type => :language_and_script,
                    :corresponding_to_association => :language_and_script)
end
