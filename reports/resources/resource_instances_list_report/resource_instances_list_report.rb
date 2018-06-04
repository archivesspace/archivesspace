class ResourceInstancesListReport < AbstractReport

  register_report

  def template
    'resource_instances_list_report.erb'
  end

  def query
    results = db[:resource].
      select(Sequel.as(:id, :resourceId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:title, :title),
             Sequel.as(:identifier, :resourceIdentifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extent_number)).
       filter(:repo_id => @repo_id)
    info[:total_count] = results.count
    info[:total_extent] = db.from(results).sum(:extent_number)
    results
  end

end
