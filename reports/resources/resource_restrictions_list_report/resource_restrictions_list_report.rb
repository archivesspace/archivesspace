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
             # Sequel.as(:restrictions_apply, :restrictionsApply),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extentNumber)).
       filter(:repo_id => @repo_id)
  end

end
