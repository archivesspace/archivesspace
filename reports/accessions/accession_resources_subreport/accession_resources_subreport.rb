class AccessionResourcesSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query_string
    "select identifier, title
    from resource, spawned_rlshp
    where spawned_rlshp.accession_id = #{db.literal(@accession_id)}
      and spawned_rlshp.resource_id = resource.id"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :identifier)
  end

end
