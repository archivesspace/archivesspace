class ResourceLocationsSubreport < AbstractSubreport

  def initialize(parent_report, resource_id)
    super(parent_report)
    @resource_id = resource_id
  end

  def query_string
    "select distinct
	    location.title as location,
      GROUP_CONCAT(distinct if(container_type is null, top_container.indicator, 
        CONCAT(container_type, ' ', top_container.indicator))
        SEPARATOR ', ') as containers

    from
    
	    (select instance.id as instance_id from instance

      left outer join archival_object
        on instance.archival_object_id = archival_object.id

      where instance.resource_id = #{db.literal(@resource_id)}
        or archival_object.root_record_id
        = #{db.literal(@resource_id)}) as instances
    
      natural join sub_container
    
      join top_container_link_rlshp
        on sub_container.id = top_container_link_rlshp.sub_container_id
    
      join top_container
        on top_container_link_rlshp.top_container_id = top_container.id
    
      join top_container_housed_at_rlshp
        on top_container.id = top_container_housed_at_rlshp.top_container_id
    
      join location on top_container_housed_at_rlshp.location_id = location.id
    
      natural left outer join
      (select id as type_id, value as container_type from enumeration_value) as enum

    group by location.id"
  end

end
