class AccessionInventoryReport < AbstractReport
  register_report

  def query
    info[:total_count] = db[:accession].count
    records = db.fetch(query_string)
    info[:number_with_inventories] = records.count
    records
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    row[:linked_resources] = AccessionResourcesSubreport.new(self, row[:id]).get_content
    row.delete(:id)
  end

  def query_string
    "select
      id,
      identifier as accession_number,
      title as record_title,
      accession_date as accession_date,
      inventory,
      date_expression,
      begin_date,
      end_date,
      bulk_begin_date,
      bulk_end_date,
      container_summary,
      extent_number,
      extent_type

    from accession

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
        accession_id as id,
        group_concat(distinct expression separator ', ') as date_expression,
        group_concat(distinct begin separator ', ') as begin_date,
        group_concat(distinct end separator ', ') as end_date
      from date, enumeration_value
      where date.date_type_id = enumeration_value.id and enumeration_value.value = 'inclusive'
      group by accession_id) as inclusive_date

      natural left outer join
      (select
        accession_id as id,
        group_concat(distinct begin separator ', ') as bulk_begin_date,
        group_concat(distinct end separator ', ') as bulk_end_date
      from date, enumeration_value
      where date.date_type_id = enumeration_value.id and enumeration_value.value = 'bulk'
      group by accession_id) as bulk_date

    where accession.repo_id = 2 and not accession.inventory is null"
  end

  def page_break
    false
  end
end
