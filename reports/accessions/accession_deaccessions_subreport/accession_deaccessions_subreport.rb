class AccessionDeaccessionsSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def do_query

    results = []

    db[:deaccession]
        .filter(:accession_id => @accession_id)
        .select(Sequel.as(:id, :deaccession_id),
                Sequel.as(:description, :description),
                Sequel.as(:notification, :notification_sent),
                Sequel.as(Sequel.lit("GetDeaccessionDate(id)"), :date),
                Sequel.as(Sequel.lit("GetDeaccessionExtent(id)"), :extent_number),
                Sequel.as(Sequel.lit("GetDeaccessionExtentType(id)"), :extent_type))
        .each do |result|
      row = result.to_hash
      row.delete(:deaccession_id)
      ReportUtils.fix_extent_format(row)
      ReportUtils.fix_boolean_fields(row, [:notification_sent])
      results.push(row)
    end

    results.empty? ? nil : results
  end
end
