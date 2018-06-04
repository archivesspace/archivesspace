class ResourcesTopContainersSubreport < AbstractSubreport
  def initialize(parent_report, resource_id)
    super(parent_report)
    @resource_id = resource_id
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "select distinct
	type_1 as type,
    top_container.indicator as indicator,
    top_container.id as id
from
	(top_container
    left outer join (select id, value as type_1 from enumeration_value) as tbl1
		on tbl1.id = top_container.type_id
    join top_container_link_rlshp
		on top_container_link_rlshp.top_container_id = top_container.id
    join sub_container
		on top_container_link_rlshp.sub_container_id = sub_container.id
	join
    (select instance.id as id,
        ifnull(instance.resource_id, archival_object.root_record_id) as resource_id
	from instance
	left outer join archival_object
		on instance.archival_object_id = archival_object.id) as instances
    on sub_container.instance_id = instances.id)

where instances.resource_id = #{@resource_id}"
  end

  def fix_row(row)
    row[:container_profile] = query_profiles(row[:id])
    ReportUtils.fix_container_indicator(row)
    row[:instances] = ResourceInstancesSubreport.new(self, @resource_id, row[:id]).get
    row.delete(:id)
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
end