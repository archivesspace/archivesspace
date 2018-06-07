class LocationResourcesSubreport < AbstractSubreport
  def initialize(parent_report, location_id)
    super(parent_report)
    @location_id = location_id
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "select distinct
        resource.identifier as identifier,
        resource.title as title
    from location
        join top_container_housed_at_rlshp on top_container_housed_at_rlshp.id = location.id
        join top_container on top_container.id = top_container_housed_at_rlshp.top_container_id
        join top_container_link_rlshp on top_container_link_rlshp.top_container_id = top_container.id
        join sub_container on sub_container.id = top_container_link_rlshp.sub_container_id
        join instance on instance.id = sub_container.instance_id
        left outer join archival_object on archival_object.id = instance.archival_object_id
        join resource on resource.id = archival_object.root_record_id or resource.id = instance.resource_id
    where location.id = #{@location_id} and resource.repo_id = #{@repo_id}"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
  end
end
