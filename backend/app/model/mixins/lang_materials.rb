module LangMaterials

  def self.included(base)
    require_relative '../lang_material'

    base.one_to_many(:lang_material)
    LangMaterial.many_to_one base.table_name

    base.def_nested_record(:the_property => :lang_materials,
                           :contains_records_of_type => :lang_material,
                           :corresponding_to_association  => :lang_material)
  end

end
