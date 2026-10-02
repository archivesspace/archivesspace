class AccessionReport < AbstractReport
  register_report(
    params: [['include_suppressed', 'IncludeSuppressed', 'Include suppressed records']]
  )

  def fix_row(row)
    clean_row(row)
    add_sub_reports(row)
  end

  def query
    results = db.fetch(query_string)
    info[:number_of_accessions] = results.count
    results
  end

  def query_string
    "select
      accession.id as accession_id,
      identifier as accession_number,
      accession_mlc.title as record_title,
      accession_date as accession_date,
      accession_mlc.provenance as provenance,
      extent_number,
      extent_type,
      accession_mlc.general_note as general_note,
      container_summary,
      date_expression,
      begin_date,
      end_date,
      bulk_begin_date,
      bulk_end_date,
      acquisition_type_id as acquisition_type,
      retention_rule,
      accession_mlc.content_description as description_note,
      accession_mlc.condition_description as condition_note,
      accession_mlc.inventory as inventory,
      accession_mlc.disposition as disposition_note,
      restrictions_apply,
      access_restrictions,
      accession_mlc.access_restrictions_note as access_restrictions_note,
      use_restrictions,
      accession_mlc.use_restrictions_note as use_restrictions_note,
      ifnull(rights_transferred, false) as rights_transferred,
      rights_transferred_note,
      ifnull(acknowledgement_sent, false) as acknowledgement_sent
    from accession
      #{mlc_join('accession')}
      left outer join
        (select
          accession_id as id,
          sum(number) as extent_number,
          GROUP_CONCAT(distinct extent_type_id SEPARATOR ', ') as extent_type,
          GROUP_CONCAT(distinct extent.container_summary SEPARATOR ', ') as container_summary
        from extent
        group by accession_id) as extent_cnt on extent_cnt.id = accession.id

      left outer join
        (select
          accession_id as id,
          group_concat(distinct expression separator ', ') as date_expression,
          group_concat(distinct begin separator ', ') as begin_date,
          group_concat(distinct end separator ', ') as end_date
        from date, enumeration_value
        where date.date_type_id = enumeration_value.id and enumeration_value.value = 'inclusive'
        group by accession_id) as inclusive_date on inclusive_date.id = accession.id

      left outer join
        (select
          accession_id as id,
          group_concat(distinct begin separator ', ') as bulk_begin_date,
          group_concat(distinct end separator ', ') as bulk_end_date
          from date, enumeration_value
          where date.date_type_id = enumeration_value.id and enumeration_value.value = 'bulk'
          group by accession_id) as bulk_date on bulk_date.id = accession.id

      left outer join
        (select
          accession_id as id,
          count(*) != 0 as rights_transferred,
          group_concat(outcome_note separator ', ') as rights_transferred_note
        from event_link_rlshp, event, enumeration_value
        where event_link_rlshp.event_id = event.id
          and event.event_type_id = enumeration_value.id and enumeration_value.value = 'copyright_transfer'
        group by event_link_rlshp.accession_id) as rights_transferred on rights_transferred.id = accession.id

      left outer join
        (select
          accession_id as id,
          count(*) != 0 as acknowledgement_sent
        from event_link_rlshp, event, enumeration_value
        where event_link_rlshp.event_id = event.id
          and event.event_type_id = enumeration_value.id and enumeration_value.value = 'acknowledgement_sent'
        group by event_link_rlshp.accession_id) as acknowledgement_sent on acknowledgement_sent.id = accession.id

    where accession.repo_id = #{db.literal(@repo_id)}#{suppressed_filter('accession')}"
  end

  def clean_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.get_enum_values(row, [:acquisition_type, :extent_type])
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, %i[restrictions_apply
                                           access_restrictions use_restrictions
                                           rights_transferred
                                           acknowledgement_sent])
  end

  def add_sub_reports(row)
    id = row[:accession_id]
    row[:deaccessions] = AccessionDeaccessionsSubreport.new(self, id).get_content
    row[:locations] = AccessionLocationsSubreport.new(self, id).get_content
    row[:names] = AccessionNamesSubreport.new(self, id).get_content
    row[:subjects] = AccessionSubjectsSubreport.new(self, id).get_content
    row.delete(:accession_id)
  end

  def identifier_field
    :accession_number
  end
end
