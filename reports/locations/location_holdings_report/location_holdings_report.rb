class LocationHoldingsReport < AbstractReport

  QUERY_BASE = "select
	location_id as id,
  building,
	floor,
  room,
	location_in_room,
	location_url,
	location_profile,
	location_barcode
from

	(select
		id as location_id,
		building,
		floor,
		room,
		GetCoordinate(id) as location_in_room,
		concat('/locations/', id) as location_url,
		barcode as location_barcode
	from location) as tbl1

	natural left outer join

	(select name as location_profile, location_id
	from
		location_profile join location_profile_rlshp
			on location_profile.id = location_profile_id
	) as tbl2".freeze

  QUERY_ORDER = 'order by building, floor, room, location_in_room, location_url'.freeze

  register_report(
    params: [['locations', 'LocationList', 'The locations of interest']]
  )

  include JSONModel

  attr_reader :building, :repository_uri, :start_location, :end_location

  def initialize(params, job, db)
    super

    if ASUtils.present?(params['building'])
      @building = params['building']
      @building = @building.gsub("'", "''")
    elsif ASUtils.present?(params['repository_uri'])
      @repository_uri = params['repository_uri']

      RequestContext.open(repo_id: JSONModel(:repository).id_for(@repository_uri)) do
        unless current_user.can?(:view_repository)
          raise AccessDeniedException, 'User does not have access to view the requested repository'
        end
      end
    else
      @start_location = Location.get_or_die(JSONModel(:location).id_for(params['location_start']['ref']))

      if ASUtils.present?(params['location_end'])
        @end_location = Location.get_or_die(JSONModel(:location).id_for(params['location_end']['ref']))
      end
    end
  end

  def query
    query_string = if building
                     "#{QUERY_BASE} where building = '#{building}' #{QUERY_ORDER}"
                   elsif repository_uri
                     "#{QUERY_BASE} where location_id in
                     (select distinct location_id from
                     top_container join top_container_housed_at_rlshp
                     on top_container_id = top_container.id where
                     repo_id = #{JSONModel.parse_reference(repository_uri)[:id]})
                     #{QUERY_ORDER}"
                   else
                     # TODO: add option for range
                     "#{QUERY_BASE} where location_id = #{start_location.id} #{QUERY_ORDER}"
                   end
    db.fetch(query_string)
  end

  def fix_row(row)
    row[:containers] = LocationContainersSubreport
                                .new(self, row[:id]).get
    row.delete(:id)
  end

  def identifier_field
    :location_url
  end

end
