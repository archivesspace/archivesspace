class AssessmentMaterial < Sequel::Model(:assessment_material)

  include ASModel
  corresponds_to JSONModel(:assessment_material)

  set_model_scope :global
end
