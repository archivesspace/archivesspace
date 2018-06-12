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
      value as rating
    from assessment_attribute, assessment_attribute_definition
    where assessment_attribute.assessment_id = #{@assessment_id}
      and type = 'rating'
      and assessment_attribute.assessment_attribute_definition_id
        = assessment_attribute_definition.id"
  end

end
