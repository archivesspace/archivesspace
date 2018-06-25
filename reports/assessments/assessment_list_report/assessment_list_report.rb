class AssessmentListReport < AbstractReport
  BOOLEAN_FIELDS = [:accession_report, :appraisal, :container_list, :catalog_record,
                    :control_file, :deed_of_gift, :finding_aid_ead, :finding_aid_online,
                    :finding_aid_paper, :finding_aid_word, :finding_aid_spreadsheet,
                    :related_eac_records, :review_required, :inactive,
                    :sensitive_material].freeze

  register_report(
    params: [['scope_by_date', 'Boolean', 'Scope records by a date range'],
             ['from', Date, 'The start of report range'],
             ['to', Date, 'The start of report range']]
  )

  def initialize(params, job, db)
    super
    from = params['from'].to_s.empty? ? Time.at(0).to_s : params['from']
    to = params['to'].to_s.empty? ? Time.parse('9999-01-01').to_s : params['to']

    @date_scope = params['scope_by_date']

    if @date_scope
      from = params['from']
      to = params['to']

      raise 'Date range not specified.' if from === '' || to === ''

      @from = DateTime.parse(from).to_time.strftime('%Y-%m-%d %H:%M:%S')
      @to = DateTime.parse(to).to_time.strftime('%Y-%m-%d %H:%M:%S')

      info[:scoped_by_date_range] = "#{@from} & #{@to}"
    end
  end

  def query
    results = db.fetch(query_string)
    info[:total_count] = results.count
    results
  end

  def query_string
    date_condition = if @date_scope
                      "survey_begin > 
                      #{@from.split(' ')[0].gsub('-', '')} 
                      and survey_begin < 
                      #{@to.split(' ')[0].gsub('-', '')}"
                    else
                      '1=1'
                    end
    "select
      null as linked_records,
      id,
      accession_report,
      appraisal,
      container_list,
      catalog_record,
      control_file,
      deed_of_gift,
      finding_aid_ead,
      finding_aid_online,
      finding_aid_paper,
      finding_aid_word,
      finding_aid_spreadsheet,
      related_eac_records,
      surveyed_by,
      survey_begin,
      survey_end,
      surveyed_duration,
      surveyed_extent,
      review_required,
      reviewer,
      inactive,
      sensitive_material,
      purpose,
      scope,
      general_assessment_note,
      exhibition_value_note,
      existing_description_notes,
      review_note,
      monetary_value,
      monetary_value_note,
      formats,
      special_format_note,
      conservation_issues,
      conservation_note
    from assessment
        
      natural left outer join
      (select
        assessment_id as id,
        group_concat(name_person.sort_name separator ', ') as surveyed_by
      from surveyed_by_rlshp
        join agent_person on agent_person.id = surveyed_by_rlshp.agent_person_id
        join name_person on name_person.agent_person_id = agent_person.id  
      group by assessment_id) as surveyers
      
      natural left outer join
      (select
        assessment_id as id,
        group_concat(name_person.sort_name separator ', ') as reviewer
      from assessment_reviewer_rlshp
        join agent_person on agent_person.id = assessment_reviewer_rlshp.agent_person_id
        join name_person on name_person.agent_person_id = agent_person.id
      group by assessment_id) as reviewers
      
      natural left outer join
      (select
        assessment_attribute.assessment_id as id,
        group_concat(if(type = 'format', label, null) separator ', ') as formats,
        group_concat(if(type = 'conservation_issue', label, null) separator ', ')
          as conservation_issues
      from assessment_attribute
        join assessment_attribute_definition
          on assessment_attribute.assessment_attribute_definition_id
            = assessment_attribute_definition.id
      group by assessment_attribute.assessment_id) as attributes
    where repo_id = #{@repo_id} and #{date_condition}"
  end

  def fix_row(row)
    ReportUtils.fix_boolean_fields(row, BOOLEAN_FIELDS)
    ReportUtils.fix_decimal_format(row, [:monetary_value])
    row[:ratings] = AssessmentRatingSubreport.new(self, row[:id]).get_content
    row[:linked_records] = AssessmentLinkedRecordsSubreport.new(self, row[:id])
                           .get_content
  end

  def identifier_field
    :id
  end
end
