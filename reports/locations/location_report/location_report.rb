class LocationReport < AbstractReport
  register_report

  def query_string
    "select
      id,
      title as record_title,
      building,
      floor,
      room,
      area,
      barcode,
      classification as classification_number,
      coordinate_1_label,
      coordinate_1_indicator,
      coordinate_2_label,
      coordinate_2_indicator,
      coordinate_3_label,
      coordinate_3_indicator
    from location"
  end

  def fix_row(row)
    ReportUtils.get_location_coordinate(row)
    row[:accessions] = LocationAccessionsSubreport.new(
      self, row[:id], false).get_content
    row[:resources] = LocationResourcesSubreport.new(
      self, row[:id], false).get_content
    row.delete(:id)
  end

  def page_break
    false
  end

  def identifier_field
    :record_title
  end

end
