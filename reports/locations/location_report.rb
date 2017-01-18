class LocationReport < AbstractReport
  register_report({
                    :uri_suffix => "location_report",
                    :description => "Displays a list of locations, indicating any accessions or resources assigned to defined locations."
                  })

  def title
    "Location Report"
  end

  def template
    "location_report.erb"
  end

  def total_count
    query.count
  end

  def query
    db[:location]
      .select(Sequel.as(:id, :location_id),
              Sequel.as(:building, :location_building),
              Sequel.as(:title, :location_title),
              Sequel.as(:floor, :location_floor),
              Sequel.as(:room, :location_room),
              Sequel.as(:area, :location_area),
              Sequel.as(:barcode, :location_barcode),
              Sequel.as(:classification, :location_classification),
              Sequel.as(Sequel.lit("GetCoordinate(id)"), :location_coordinate))
  end

end
