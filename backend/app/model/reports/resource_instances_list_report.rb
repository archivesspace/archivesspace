class ResourceInstancesListReport < AbstractReport

  register_report({
                    :uri_suffix => "resource_instances_list_report",
                    :description => "Displays resource(s) and all specified location information. Report contains title, resource identifier, level, date range, and assigned locations.",
                  })

  def title
    "Resources and Instances List"
  end

  def template
    'resource_instances_list_report.erb'
  end

  def query
    db[:resource].
      select(Sequel.as(:id, :resourceId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:title, :title),
             Sequel.as(:identifier, :resourceIdentifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extentNumber))
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end

  # Total Extent of Resources
  def total_extent
    @total_extent ||= db.from(self.query).sum(:extentNumber)
  end

end
