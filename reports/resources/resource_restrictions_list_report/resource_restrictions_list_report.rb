class ResourceRestrictionsListReport < AbstractReport

  register_report

  def template
    'resource_restrictions_list_report.erb'
  end

  def query
    db[:resource].
      select(Sequel.as(:id, :resourceId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:title, :title),
             Sequel.as(:identifier, :resourceIdentifier),
             Sequel.as(:restrictions, :restrictionsApply),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extentNumber))
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end

  def restricted_count
    @restricted_count ||= db.from(self.query)
                            .filter(:restrictionsApply => 1)
                            .count
  end

  # Total Extent of Resources
  def total_extent
    @total_extent ||= db.from(self.query).sum(:extentNumber)
  end

  # Total Extent of Restricted Resources
  def total_restricted_extent
    @total_restricted_extent ||= db.from(self.query)
                                   .filter(:restrictionsApply => 1)
                                   .sum(:extentNumber)
  end

end
