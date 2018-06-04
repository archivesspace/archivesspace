class ResourceDeaccessionsListReport < AbstractReport

  register_report

  def template
    'resource_deaccessions_list_report.erb'
  end

  def query
    results = db[:resource]
      .filter(Sequel.lit('GetResourceHasDeaccession(id)') => 1)
      .select(Sequel.as(:id, :id),
             Sequel.as(:title, :title),
             Sequel.as(:identifier, :identifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :date_expression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extent_number))
      .filter(:repo_id => @repo_id)
    get_total_extent(results)
    info['total_deaccessions_extent'] = 0
    info['total_count'] = results.count
    results
  end

  # Total Extent of Resources
  def get_total_extent(results)
    info['total_extent'] = db.from(results).sum(:extent_number)
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
    deaccessions = ResourceDeaccessionsSubreport.new(self, row[:id])
    row[:deaccessions] = deaccessions.get
    info['total_deaccessions_extent'] += deaccessions.total_extent
    row.delete(:id)
    row.delete(:extent_number)
  end

  def after_tasks
    ReportUtils.fix_decimal_format(info, %w[total_extent total_deaccessions_extent])
  end

  def page_break
    false
  end

  def identifier_field
    :identifier
  end

end
