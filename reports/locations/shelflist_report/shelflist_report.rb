class ShelflistReport < AbstractReport
  register_report

  def query_string
  	"select
	  id,
	  title as record_title,
	  temporary_id as temporary_location,
	  building,
	  floor,
	  room,
	  area,
	  barcode as location_barcode,
	  coordinate_1_label,
	  coordinate_1_indicator,
	  coordinate_2_label,
	  coordinate_2_indicator,
	  coordinate_3_label,
	  coordinate_3_indicator,
	  null as location_in_room,
	  location_profile
	  
	from location
	  natural left outer join
	  (select
	    location_profile_rlshp.location_id as id,
	    group_concat(location_profile.name separator '; ') as location_profile
	  from location_profile_rlshp, location_profile
	  where location_profile.id = location_profile_rlshp.location_profile_id
	  group by location_profile_rlshp.location_id) as profiles"
  end

  def fix_row(row)
  	ReportUtils.get_location_coordinate(row)
  	ReportUtils.get_enum_values(row, [:temporary_location])
  	row[:resources] = LocationResourcesSubreport.new(self, row[:id], true)
  												.get_content
  	row[:accessions] = LocationAccessionsSubreport.new(self, row[:id], true)
  												  .get_content
  	row.delete(:id)
  end

  def identifier_field
  	:record_title
  end

end