class LocationReport < AbstractReport
  register_report

  def query
    results = db[:location]
      .select(Sequel.as(:id, :id),
              Sequel.as(:building, :building),
              Sequel.as(:floor, :floor),
              Sequel.as(:room, :room),
              Sequel.as(:area, :area),
              Sequel.as(:barcode, :barcode),
              Sequel.as(:classification, :classification_number),
              Sequel.as(Sequel.lit("GetCoordinate(id)"), :coordinates))
    info['total_count'] = results.count
    results
  end

  def fix_row(row)
    row[:accessions] = LocationAccessionsSubreport.new(self, row[:id]).get
    row[:resources] = LocationResourcesSubreport.new(self, row[:id]).get
    row.delete(:id)
  end

  def page_break
    false
  end

  def identifier_field
    :building
  end

end
