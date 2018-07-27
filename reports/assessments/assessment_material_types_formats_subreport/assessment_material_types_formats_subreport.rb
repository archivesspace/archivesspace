class AssessmentMaterialTypesFormatsSubreport < AbstractSubreport

  register_subreport('formats', ['assessment'],
    :translation => 'assessment._frontend.formats')

  def initialize(parent_report, assessment_id)
    super(parent_report)
    @assessment_id = assessment_id
  end

  def query_string
    "select
      label as _format
    from assessment_attribute
      join assessment_attribute_definition
        on assessment_attribute_definition.id
        = assessment_attribute.assessment_attribute_definition_id

    where assessment_attribute.assessment_id = #{db.literal(@assessment_id)}
      and assessment_attribute_definition.type = 'format'"
  end

  def self.field_name
    'formats'
  end

end
