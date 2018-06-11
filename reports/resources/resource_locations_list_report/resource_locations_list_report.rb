class ResourceLocationsListReport < AbstractReport

  register_report

  def query
    results = db[:resource].
      select(Sequel.as(:id, :id),
             Sequel.as(:title, :resource_title),
             Sequel.as(:identifier, :identifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dates),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extent_number)).
       filter(:repo_id => @repo_id)
    info[:total_extent] = db.from(results).sum(:extent_number)
    ReportUtils.fix_decimal_format(info, [:total_extent])
    info[:total_count] = results.count
    results
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
    row[:locations] = ResourceLocationsSubreport.new(self, row[:id]).get_content
    row.delete(:id)
    row.delete(:extent_number)
  end

  def identifier_field
    :identifier
  end

end
