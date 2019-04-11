class LocationHoldingsReport < AbstractReport

  register_report(
    params: [['locations', 'LocationList', 'The locations of interest']]
  )

  attr_reader :building, :repository_uri, :start_location, :end_location

  def initialize(params, job, db)
    super

    if ASUtils.present?(params['building'])
      @building = params['building']
      @building = @building.gsub("'", "''")
    elsif ASUtils.present?(params['repository_uri'])
      @repository_uri = params['repository_uri']
      @repo_id = JSONModel.parse_reference(@repository_uri)[:id]

      RequestContext.open(repo_id: @repo_id) do
        unless current_user.can?(:view_repository)
          raise AccessDeniedException, 'User does not have access to view the requested repository'
        end
      end
    elsif ASUtils.present?(params['location_end'])
      @end_location = Location.get_or_die(JSONModel(:location).id_for(params['location_end']['ref']))
      @start_location = Location.get_or_die(JSONModel(:location).id_for(params['location_start']['ref']))
    else
      @start_location = Location.get_or_die(JSONModel(:location).id_for(params['location_start']['ref']))
    end
  end

  def query_string
    condition = if building
                  "building = #{db.literal(building)}"
                elsif repository_uri
                  '1=1'
                elsif end_location
                  range_condition
                else
                  "location_id = #{db.literal(start_location.id)}"
                end
    "select
      record_title,
      location_id as id,
      building,
      floor,
      room,
      coordinate_1_label,
      coordinate_1_indicator,
      coordinate_2_label,
      coordinate_2_indicator,
      coordinate_3_label,
      coordinate_3_indicator,
      location_url,
      location_profile,
      location_barcode
    from

      (select
        id as location_id,
        title as record_title,
        building,
        floor,
        room,
        coordinate_1_label,
        coordinate_1_indicator,
        coordinate_2_label,
        coordinate_2_indicator,
        coordinate_3_label,
        coordinate_3_indicator,
        concat('/locations/', id) as location_url,
        barcode as location_barcode
      from location) as tbl1

      natural left outer join

      (select name as location_profile, location_id
      from
        location_profile join location_profile_rlshp
          on location_profile.id = location_profile_id) as tbl2

    where #{condition}"
  end

  def range_condition
    # Find the most specific mismatch between the two locations: building -> floor -> room -> area -> c1 -> c2 -> c3
    properties_to_compare = [:building, :floor, :room, :area]

    [1, 2, 3].each do |coordinate|
      label = "coordinate_#{coordinate}_label"
      if !start_location[label].nil? && start_location[label] == end_location[label]
        properties_to_compare << "coordinate_#{coordinate}_indicator".intern
      else
        break
      end
    end

    matching_properties = []
    determinant_property = nil

    properties_to_compare.each do |property|

      if start_location[property] && end_location[property]

        if start_location[property] == end_location[property]
          # If both locations have the same value for this property, we'll skip it for the purposes of our range calculation
          matching_properties << property
        else
          # But if they have different values, that's what we'll use for the basis of our range
          determinant_property = property
          break
        end

      elsif !start_location[property] && !end_location[property]
        # If neither location has a value for this property, skip it
        next

      else
        # If we hit a property that only one location has a value for, we can't use it for a range calculation
        break
      end

    end

    if matching_properties.empty? && determinant_property.nil?
      # an empty dataset
      return 'false'
    end

    filters = []

    matching_properties.each do |property|
      filters << "#{property} = #{db.literal(start_location[property])}"
    end

    if determinant_property
      range_start, range_end = [start_location[determinant_property], end_location[determinant_property]].sort
      filters << "#{determinant_property} >= #{db.literal(range_start)}"
      filters << "#{determinant_property} <= #{db.literal(range_end)}"
    end

    filters.collect { |filter| "(#{filter})" }.join(' AND ')
  end                

  def fix_row(row)
    ReportUtils.get_location_coordinate(row)
    row[:containers] = LocationContainersSubreport
                                .new(self, row[:id]).get_content
    row.delete(:id)
  end

  def identifier_field
    :record_title
  end

end
