module AssessmentMaterials

  def self.included(base)
    base.one_to_many :assessment_material

    base.def_nested_record(:the_property => :materials,
                           :contains_records_of_type => :assessment_material,
                           :corresponding_to_association  => :assessment_material)
  end

end
