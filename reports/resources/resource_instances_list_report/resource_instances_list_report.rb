class ResourceInstancesListReport < AbstractReport

  register_report

  def query
    job.write_output('Fetching resources...')
    results = db[:resource].
      select(Sequel.as(:id, :id),
             Sequel.as(:title, :resource_title),
             Sequel.as(:identifier, :identifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :date),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extent_number)).
       filter(:repo_id => @repo_id)
    info[:total_count] = results.count
    info[:total_extent] = db.from(results).sum(:extent_number)
    ReportUtils.fix_decimal_format(info, [:total_extent])
    job.write_output("Found #{info[:total_count]} resources.")
    results
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
    job.write_output("Fetching instances for resource #{row[:identifier]}...")
    row[:containers] = ResourcesTopContainersSubreport.new(self, row[:id]).get
    row.delete(:id)
    row.delete(:extent_number)
  end

  def identifier_field
    :identifier
  end

end
