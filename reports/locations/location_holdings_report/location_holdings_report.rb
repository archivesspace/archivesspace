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
	) as tbl2"

  QUERY_ORDER = 'order by building, floor, room, location_in_room, location_url'

  register_report({
                      :params => [['locations', 'LocationList', 'The locations of interest']]
                  })

  include JSONModel

  attr_reader :building, :repository_uri, :start_location, :end_location

  def initialize(params, job, db)
    super

    if ASUtils.present?(params['building'])
      @building = params['building']
    elsif ASUtils.present?(params['repository_uri'])
      @repository_uri = params['repository_uri']

      RequestContext.open(:repo_id => JSONModel(:repository).id_for(@repository_uri)) do
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
                     "#{QUERY_BASE} where building = '#{building.gsub!("'", "''")}' #{QUERY_ORDER}"
                   elsif repository_uri
                     "#{QUERY_BASE} where location_id in
                     (select distinct location_id from
                     top_container join top_container_housed_at_rlshp
                     on top_container_id = top_container.id where
                     repo_id = #{JSONModel.parse_reference(repository_uri)[:id]})
                     #{QUERY_ORDER}"
                   else
                     # TODO: add option for range
                     "#{QUERY_BASE} where id = #{start_location.id} #{QUERY_ORDER}"
                   end
    results = db.fetch(query_string)
    location_array = []

    results.each do |row|
      location = row.to_hash
      location[:containers] = query_containers(location[:id])
      location.delete(:id)
      location_array.push(location) if location[:containers]
    end
    location_array
  end

  def query_containers(location_id)
    query_string = "select
	indicator as top_container_indicator,
	barcode as top_container_barcode,
	ils_item_id,
	ils_holding_id,
  name as repository,
  tbl.id as id from
	(select top_container_id as id from top_container_housed_at_rlshp
  where location_id = #{location_id}) as tbl
    natural join top_container
    join repository on repo_id = repository.id"
    containers = db.fetch(query_string)
    container_array = []
    containers.each do |container_row|
      container = container_row.to_hash
      container[:container_profile] = query_profiles(container[:id])
      container[:resources] = query_resources(container[:id])
      container[:accessions] = query_accessions(container[:id])
      container.delete(:id)
      container_array.push(container)
    end
    container_array.empty? ? nil : container_array
  end

  def query_profiles(container_id)
    query_string = "select name from
	container_profile join top_container_profile_rlshp
    on container_profile.id = container_profile_id
where top_container_id = #{container_id}"
    profiles = db.fetch(query_string)
    profile_string = ''
    profiles.each do |profile_row|
      profile = profile_row.to_hash
      next unless profile[:name]
      profile_string += ', ' if profile_string != ''
      profile_string += profile[:name]
    end
    profile_string.empty? ? nil : profile_string
  end

  def query_resources(container_id)
    query_string = "select identifier, title from
	resource natural join
	(select distinct GetResourceIdentiferForInstance(instance_id) as identifier, repo_id from
		sub_container join top_container_link_rlshp
		on sub_container.id = sub_container_id
        join top_container on top_container_id = top_container.id
	where top_container_id = #{container_id}) as tbl
where resource.repo_id = tbl.repo_id"
    resources = db.fetch(query_string)
    resource_array = []
    resources.each do |resource_row|
      resource = resource_row.to_hash
      identifier = ASUtils.json_parse(resource[:identifier])
      resource[:identifier] = identifier.compact.join('/')
      resource_array.push(resource)
    end
    resource_array.empty? ? nil : resource_array
  end

  def query_accessions(container_id)
    query_string = "select identifier, title from
	accession join instance
    on accession.id = accession_id
    join sub_container
    on instance.id = instance_id
    join top_container_link_rlshp
    on sub_container.id = sub_container_id
where top_container_id = #{container_id}"
    accessions = db.fetch(query_string)
    accession_array = []
    accessions.each do |accession_row|
      accession = accession_row.to_hash
      identifier = ASUtils.json_parse(accession[:identifier])
      accession[:identifier] = identifier.compact.join('/')
      accession_array.push(accession)
    end
    accession_array.empty? ? nil : accession_array
  end

  def identifier(record)
    "#{title}: #{record[:location_url]}"
  end

end
