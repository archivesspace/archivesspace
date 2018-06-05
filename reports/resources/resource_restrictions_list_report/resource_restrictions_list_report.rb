class ResourceRestrictionsListReport < AbstractReport
  register_report

  def query
    results = db[:resource]
      .select(Sequel.as(:id, :id),
              Sequel.as(:title, :resource_title),
              Sequel.as(:identifier, :identifier),
              # Sequel.as(:restrictions_apply, :restrictionsApply),
              Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
              Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dates),
              Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extent_number))
      .filter(repo_id: @repo_id)
    info[:total_count] = results.count
    info[:total_extent] = db.from(results).sum(:extent_number)
    ReportUtils.fix_decimal_format(info, [:total_extent])
    results
  end

  def fix_row(row)
    row.delete(:extent_number)
    ReportUtils.fix_identifier_format(row)
    row[:locations] = ResourceLocationsSubreport.new(self, row[:id]).get
    row.delete(:id)
  end

  def identifier_field
    :identifier
  end
end
