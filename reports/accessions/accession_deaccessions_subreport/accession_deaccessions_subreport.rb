class AccessionDeaccessionsSubreport < AbstractSubreport
  attr_accessor :total_extent

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
    @total_extent = nil
  end

  def query
    results = db[:deaccession]
              .filter(accession_id: @accession_id)
              .select(Sequel.as(:description, :description),
                      Sequel.as(:notification, :notification_sent),
                      Sequel.as(Sequel.lit('GetDeaccessionDate(id)'), :date),
                      Sequel.as(Sequel.lit('GetDeaccessionExtent(id)'), :extent_number),
                      Sequel.as(Sequel.lit('GetDeaccessionExtentType(id)'), :extent_type))

    @total_extent = db.from(results).sum(:extent_number)

    results
  end

  def fix_row(row)
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_boolean_fields(row, [:notification_sent])
  end
end
