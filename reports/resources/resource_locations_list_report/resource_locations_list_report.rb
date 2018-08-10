class ResourceLocationsListReport < AbstractReport

  register_report

  def query
    results = db.fetch(query_string)
    info[:total_extent] = db.from(results).sum(:extent_number)
    ReportUtils.fix_decimal_format(info, [:total_extent])
    info[:total_count] = results.count
    results
  end

  def query_string
    "select
      id,
      title as record_title,
      identifier,
      level_id as level,
      dates,
      extent_number
        
    from resource

      natural left outer join
      (select
        resource_id as id,
        group_concat(ifnull(expression, if(end is null, begin,
          concat(begin, ' - ', end))) separator ', ') as dates
      from date
      group by resource_id) as record_date
      
      natural left outer join
      (select
        resource_id as id,
        sum(number) as extent_number
      from extent
      group by resource_id) as extent_cnt
        
    where repo_id = #{db.literal(@repo_id)}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:level])
    ReportUtils.fix_identifier_format(row)
    row[:locations] = ResourceLocationsSubreport.new(self, row[:id]).get_content
    row.delete(:id)
    row.delete(:extent_number)
  end

  def identifier_field
    :identifier
  end

end
