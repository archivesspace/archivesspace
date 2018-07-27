class AssessmentConservationIssuesSubreport < AbstractSubreport

  register_subreport('conservation_issues', ['assessment'],
    :translation => 'assessment._frontend.conservation_issues')

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
      and assessment_attribute_definition.type = 'conservation_issue'"
  end

  def self.field_name
    'conservation_issues'
  end

end
