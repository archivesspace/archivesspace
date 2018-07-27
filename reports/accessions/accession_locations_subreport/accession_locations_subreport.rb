class AccessionLocationsSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query_string
    "select
      location.title as location,
        GROUP_CONCAT(distinct 
        if(not container_type is null, 
          CONCAT(container_type, ' ', top_container.indicator),
          top_container.indicator)
      SEPARATOR ', ') as container
    from instance
      join sub_container on sub_container.instance_id = instance.id
      join top_container_link_rlshp on top_container_link_rlshp.sub_container_id
        = sub_container.id
      join top_container on top_container.id
        = top_container_link_rlshp.top_container_id
      left outer join top_container_profile_rlshp on top_container.id
        = top_container_profile_rlshp.top_container_id
      left outer join container_profile on container_profile.id
        = top_container_profile_rlshp.container_profile_id
      join top_container_housed_at_rlshp on
        top_container_housed_at_rlshp.top_container_id = top_container.id
      join location on location.id = top_container_housed_at_rlshp.location_id
      natural left outer join
        (select id as type_id, value as container_type
        from enumeration_value) as enum
    where instance.accession_id = #{db.literal(@accession_id)}
    group by location.id"
  end

end
