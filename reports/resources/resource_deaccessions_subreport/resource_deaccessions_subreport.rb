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
    results = db[:deaccession]
      .filter(:resource_id => @resource_id)
      .select(Sequel.as(:description, :description),
              Sequel.as(:notification, :notification),
              Sequel.as(Sequel.lit("GetDeaccessionDate(id)"), :deaccession_date),
              Sequel.as(Sequel.lit("GetDeaccessionExtent(id)"), :extent_number),
              Sequel.as(Sequel.lit("GetDeaccessionExtentType(id)"), :extent_type))
    @total_extent = db.from(results).sum(:extent_number)
    results
  end

  def fix_row(row)
    ReportUtils.fix_extent_format(row)
  end

end
