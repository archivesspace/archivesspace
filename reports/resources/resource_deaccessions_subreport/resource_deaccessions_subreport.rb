class ResourceDeaccessionsSubreport < AbstractSubreport

  attr_accessor :total_extent

  def initialize(parent_report, resource_id)
    super(parent_report)
    @resource_id = resource_id
    @total_extent = nil
  end

  def accession_count
    query.count
  end

  def query
    results = db.fetch(query_string)
    @total_extent = db.from(results).sum(:extent_number)
    results
  end

  def query_string
    "select
      description,
      notification as notification_sent,
      group_concat(distinct date.begin SEPARATOR ', ') as deaccession_date,
      sum(extent.number) as extent_number,
      GROUP_CONCAT(distinct extent.extent_type_id SEPARATOR ', ') as extent_type
    from deaccession
      left outer join date on date.deaccession_id = deaccession.id
      left outer join extent on extent.deaccession_id = deaccession.id
    where deaccession.resource_id = #{db.literal(@resource_id)}
    group by deaccession.id"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, [:notification_sent])
  end

end
