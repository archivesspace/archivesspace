class LocationReport < AbstractReport
  register_report

  def template
    "location_report.erb"
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
