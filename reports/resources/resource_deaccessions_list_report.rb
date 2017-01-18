class ResourceDeaccessionsListReport < AbstractReport

  register_report({
                    :uri_suffix => "resource_deaccessions_list_report",
                    :description => "Displays resource(s) and linked deaccession record(s). Report contains title, resource identifier, level, date range, linked deaccessions, creator names, and physical extent totals.",
                  })

  def title
    "Resources and Deaccession(s)"
  end

  def template
    'resource_deaccessions_list_report.erb'
  end

#   resource.`id` AS resourceId,
#      resource.`repo_id` AS repo_id,
#      resource.`title` AS title,
#      resource.`identifier` AS resourceIdentifier,
#      GetEnumValueUF(resource.`level_id`) AS level,
#      GetResourceDateExpression(resource.`id`) AS dateExpression,
#      GetResourceExtent(resource.`id`) AS extentNumber,
#      GetResourceDeaccessionExtent(resource.`id`) AS deaccessionExtentNumber
# FROM
#      `resource` resource
# WHERE
#      GetResourceHasDeaccession(resource.`id`) = 1
  def query
    db[:resource].
      filter(Sequel.lit('GetResourceHasDeaccession(id)') => 1).
      select(Sequel.as(:id, :resourceId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:title, :title),
             Sequel.as(:identifier, :resourceIdentifier),
             Sequel.as(Sequel.lit('GetEnumValueUF(level_id)'), :level),
             Sequel.as(Sequel.lit('GetResourceDateExpression(id)'), :dateExpression),
             Sequel.as(Sequel.lit('GetResourceExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetResourceDeaccessionExtent(id)'), :deaccessionExtentNumber))
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end

  # Total Extent of Resources
  def total_extent
    @total_extent ||= db.from(self.query).sum(:extentNumber)
  end

  # Total Extent of Deaccessions
  def total_extent_of_deaccessions
    return @total_extent_of_deaccessions if @total_extent_of_deaccessions

    deaccessions = db[:deaccession].where(:accession_id => self.query.select(:id))
    deaccession_extents = db[:extent].where(:deaccession_id => deaccessions.select(:id))
    
    @total_extent_of_deaccessions = deaccession_extents.sum(:number)

    @total_extent_of_deaccessions
  end

end
