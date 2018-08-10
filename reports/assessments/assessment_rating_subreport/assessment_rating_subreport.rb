class AssessmentRatingSubreport < AbstractSubreport

  register_subreport('ratings', ['assessment'],
    :translation => 'assessment._frontend.ratings')

  def initialize(parent_report, assessment_id)
    super(parent_report)
    @assessment_id = assessment_id
  end

  def query_string
    "select
      label as field,
      value as rating,
      assessment_attribute_note.note
    from assessment_attribute
      join assessment_attribute_definition
        on assessment_attribute_definition.id
        = assessment_attribute.assessment_attribute_definition_id
      
      left outer join assessment_attribute_note
        on assessment_attribute_note.assessment_id
        = assessment_attribute.assessment_id
        and assessment_attribute_note.assessment_attribute_definition_id
        = assessment_attribute_definition.id

    where assessment_attribute.assessment_id = #{db.literal(@assessment_id)}
      and assessment_attribute_definition.type = 'rating'"
  end

  def self.field_name
    'ratings'
  end

end
