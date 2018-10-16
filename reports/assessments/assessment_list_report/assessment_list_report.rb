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
    @form = params[:format]
    @att_defs = assessment_att_defs

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
                      #{db.literal(@from.split(' ')[0].gsub('-', ''))}
                      and survey_begin <
                      #{db.literal(@to.split(' ')[0].gsub('-', ''))}"
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
    where repo_id = #{db.literal(@repo_id)} and #{date_condition} and (inactive = 0 or inactive IS NULL)"
  end

  def fix_row(row)
    ReportUtils.fix_boolean_fields(row, BOOLEAN_FIELDS)
    ReportUtils.fix_decimal_format(row, [:monetary_value])
    if @form == 'csv'
      row.merge!(@att_defs)
      formats_hash = AssessmentMaterialTypesFormatsSubreport.new(
        self, row[:id]).get_content
      unless formats_hash.nil?
        formats_hash.each do | fo |
          row[ReportUtils.normalize_label(fo[:_format]).to_sym] = 'Yes'
        end
      end
      conservation_issues_hash = AssessmentConservationIssuesSubreport
        .new(self, row[:id]).get_content
      unless conservation_issues_hash.nil?
        conservation_issues_hash.each do | ci |
          row[ReportUtils.normalize_label(ci[:_format]).to_sym] = 'Yes'
        end
      end
      row.delete(:formats)
      row.delete(:conservation_issues)
      ratings_hash = AssessmentRatingSubreport.new(self, row[:id]).get_content
      unless ratings_hash.nil?
        ratings_hash.each do | ra |
          rate_label = ra[:field] + ' Rating'
          note_label = ra[:field] + ' Note' if ra[:field] != "Research Value"
          row[ReportUtils.normalize_label(rate_label).to_sym] = ra[:rating]
          row[ReportUtils.normalize_label(note_label).to_sym] = ra[:note] if ra[:field] != "Research Value"
        end
      end
    else
      row[:ratings] = AssessmentRatingSubreport.new(self, row[:id]).get_content
    end
    row[:linked_records] = AssessmentLinkedRecordsSubreport.new(self, row[:id])
                           .get_content
  end

  def identifier_field
    :id
  end

  def assessment_att_defs
    att_def = {}
    rating_def = {}
    format_def = {}
    cons_iss_def = {}
    assess_defs = AssessmentAttributeDefinitions.get(@repo_id)['definitions']
    assess_defs.each do | ad |
      if ad[:type] == "rating"
        rate_label = ad[:label] + ' Rating'
        note_label = ad[:label] + ' Note' if ad[:label] != "Research Value"
        rating_def[ReportUtils.normalize_label(rate_label).to_sym] = ''
        rating_def[ReportUtils.normalize_label(note_label).to_sym] = '' if ad[:label] != "Research Value"
      elsif ad[:type] == "format"
        format_def[ReportUtils.normalize_label(ad[:label]).to_sym] = ''
      elsif ad[:type] == "conservation_issue"
        cons_iss_def[ReportUtils.normalize_label(ad[:label]).to_sym] = ''
      end
    end
    att_def.merge!(format_def)
    att_def.merge!(cons_iss_def)
    att_def.merge!(rating_def)
  end
end
