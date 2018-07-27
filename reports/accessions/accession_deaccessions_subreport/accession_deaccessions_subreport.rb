class AccessionDeaccessionsSubreport < AbstractSubreport
  attr_accessor :total_extent

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
    @total_extent = nil
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
      group_concat(distinct date.begin SEPARATOR ', ') as date,
      sum(extent.number) as extent_number,
      GROUP_CONCAT(distinct extent.extent_type_id SEPARATOR ', ') as extent_type
    from deaccession
      left outer join date on date.deaccession_id = deaccession.id
      left outer join extent on extent.deaccession_id = deaccession.id
    where deaccession.accession_id = #{db.literal(@accession_id)}
    group by deaccession.id"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:extent_type])
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, [:notification_sent])
  end
end
