class AccessionUnprocessedReport < AbstractReport

  register_report

  def query
    results = db.fetch(query_string)
    info[:total_count] = db[:accession].count
    info[:total_unprocessed] = results.count
    info[:scoped_by_date_range] = "#{results.min(:accession_date)} & #{results.max(:accession_date)}"
    info[:total_extent] = results.sum(:extent_number)
    ReportUtils.fix_decimal_format(info, [:total_extent])
    results
  end

  def query_string
    "select
      id,
      identifier as accession_number,
      title as record_title,
      accession_date,
      container_summary,
      ifnull(cataloged, false) as cataloged,
      extent_number,
      extent_type

    from accession
  
      natural left outer join
      
      (select
        accession_id as id,
        true as processed
      from event_link_rlshp, event, enumeration_value
      where event_link_rlshp.event_id = event.id
        and event.event_type_id = enumeration_value.id
        and enumeration_value.value = 'processed'
      group by accession_id) as processed
      
      natural left outer join
      
      (select
          accession_id as id,
          sum(number) as extent_number,
          GROUP_CONCAT(distinct extent_type_id SEPARATOR ', ') as extent_type,
          GROUP_CONCAT(distinct extent.container_summary SEPARATOR ', ')
            as container_summary
      from extent
      group by accession_id) as extent_cnt
        
      natural left outer join
      
      (select
        event_link_rlshp.accession_id as id,
        count(*) != 0 as cataloged
      from event_link_rlshp, event, enumeration_value
        where event_link_rlshp.event_id = event.id
        and event.event_type_id = enumeration_value.id
        and enumeration_value.value = 'cataloged'
      group by event_link_rlshp.accession_id) as cataloged
      
    where repo_id = #{db.literal(@repo_id)}
      and processed is null"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.fix_boolean_fields(row, [:cataloged])
    row[:linked_resources] = AccessionResourcesSubreport.new(
      self, row[:id]).get_content
    row.delete(:id)
  end

  def identifier_field
    :accession_number
  end

end
