class ResourceDeaccessionsListReport < AbstractReport

  register_report

  def template
    'resource_deaccessions_list_report.erb'
  end

  def query
    results = db.fetch(query_string)
    get_total_extent(results)
    info[:total_deaccessions_extent] = 0
    info[:total_count] = results.count
    results
  end

  def query_string
    "select
      id,
      title as record_title,
      identifier,
      level_id as level,
      date_expression,
      extent_number
        
    from resource

      natural left outer join
      (select
        resource_id as id,
        group_concat(ifnull(expression, if(end is null, begin,
          concat(begin, ' - ', end))) separator ', ') as date_expression
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

  # Total Extent of Resources
  def get_total_extent(results)
    info[:total_extent] = db.from(results).sum(:extent_number)
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
    ReportUtils.get_enum_values(row, [:level])
    deaccessions = ResourceDeaccessionsSubreport.new(self, row[:id])
    row[:deaccessions] = deaccessions.get_content
    info[:total_deaccessions_extent] += deaccessions.total_extent if deaccessions.total_extent
    row.delete(:id)
    row.delete(:extent_number)
  end

  def after_tasks
    ReportUtils.fix_decimal_format(info, [:total_extent, :total_deaccessions_extent])
  end

  def page_break
    false
  end

  def identifier_field
    :identifier
  end

end
