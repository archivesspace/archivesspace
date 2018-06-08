class AccessionSubjectsNamesClassificationsListReport < AbstractReport

  register_report

  def query
    db.fetch(query_string)
  end

  def query_string
    "select
      id,
      identifier as accession_number,
      title as record_title,
      accession_date,
      restrictions_apply,
      access_restrictions,
      access_restrictions_note,
      use_restrictions,
      use_restrictions_note,
      container_summary,
      GetAccessionProcessed(id) AS `accessionProcessed`,
      GetAccessionProcessedDate(id) AS `accessionProcessedDate`,
      ifnull(cataloged, false) as cataloged,
      extent_number,
      extent_type,
      ifnull(rights_transferred, false) as rights_transferred,
      rights_transferred_note
    from accession

      natural left outer join

      (select
        accession_id as id,
        count(*) != 0 as rights_transferred,
        group_concat(outcome_note separator ', ') as rights_transferred_note
      from event_link_rlshp, event, enumeration_value
      where event_link_rlshp.event_id = event.id
        and event.event_type_id = enumeration_value.id and enumeration_value.value = 'copyright_transfer'
      group by event_link_rlshp.accession_id) as rights_transferred

      natural left outer join

      (select
        accession_id as id,
        sum(number) as extent_number,
        GROUP_CONCAT(distinct extent_type_id SEPARATOR ', ') as extent_type,
        GROUP_CONCAT(distinct extent.container_summary SEPARATOR ', ') as container_summary
      from extent
      group by accession_id) as extent_cnt

      natural left outer join

      (select
        event_link_rlshp.accession_id as id,
        count(*) != 0 as cataloged
      from event_link_rlshp, event, enumeration_value
        where event_link_rlshp.event_id = event.id
        and event.event_type_id = enumeration_value.id and enumeration_value.value = 'cataloged'
      group by event_link_rlshp.accession_id) as cataloged

    where repo_id = #{@repo_id}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.fix_extent_format(row)
    boolean_fields = [:restrictions_apply, :access_restrictions, :use_restrictions,
                     :accession_processed, :cataloged, :rights_transferred]
    ReportUtils.fix_boolean_fields(row, boolean_fields)
    row[:names] = AccessionNamesSubreport.new(self, row[:id]).get
    row[:subjects] = AccessionSubjectsSubreport.new(self, row[:id]).get
    row[:classifications] = AccessionClassificationsSubreport.new(self, row[:id]).get
    row.delete(:id)
  end

  def identifier_field
    :accession_number
  end

end
