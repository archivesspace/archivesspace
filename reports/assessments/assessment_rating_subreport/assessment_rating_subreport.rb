class AssessmentRatingSubreport < AbstractSubreport

  def initialize(parent_report, assessment_id)
    super(parent_report)
    @assessment_id = assessment_id
  end

  def query
    db.fetch(query_string)
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

    where assessment_attribute.assessment_id = #{@assessment_id}
      and assessment_attribute_definition.type = 'rating'"
  end

end
