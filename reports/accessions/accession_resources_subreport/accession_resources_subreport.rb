class AccessionResourcesSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query
    relationships = db[:spawned_rlshp].
                      filter(:spawned_rlshp__accession_id => @accession_id)

    db[:resource]
      .filter(:id => relationships.select(:resource_id))
      .select(Sequel.as(:identifier, :identifier),
              Sequel.as(:title, :title))
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :identifier)
  end

end
