class LocationHoldingsReport < AbstractReport

  register_report(
    params: [['locations', 'LocationList', 'The locations of interest']]
  )

  attr_reader :building, :repository_uri, :start_location

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
    else
      @start_location = Location.get_or_die(JSONModel(:location).id_for(params['location_start']['ref']))
    end
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    condition = if building
                  "building = '#{building}'"
                elsif repository_uri
                  '1=1'
                else
                  "location_id = #{start_location.id}"
                end
    "select
      location_title,
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
            title as location_title,
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
                  

  def fix_row(row)
    ReportUtils.get_location_coordinate(row)
    row[:containers] = LocationContainersSubreport
                                .new(self, row[:id]).get_content
    row.delete(:id)
  end

  def identifier_field
    :location_title
  end

end
