class ResourceInstancesSubreport < AbstractSubreport
  def initialize(parent_report, resource_id, top_container_id)
    super(parent_report)
    @resource_id = resource_id
    @top_container_id = top_container_id
  end

  # FIXME: might be nice to group the containers by their top container?
  # They are currently listed one per row (see hornstein)
  def query
    db.fetch(query_string)
  end

  def fix_row(row)
    ReportUtils.fix_container_indicator(row, 2)
    ReportUtils.fix_container_indicator(row, 3)
  end

  def query_string
    "select
    type_2,
    sub_container.indicator_2 as indicator_2,
    type_3,
    sub_container.indicator_3 as indicator_3,
    instance_type
from
  (select * from top_container_link_rlshp where top_container_id = #{@top_container_id}) as tbl
    join sub_container
    on tbl.sub_container_id = sub_container.id
  left outer join (select id, value as type_2 from enumeration_value) as tbl2
    on tbl2.id = sub_container.type_2_id
  left outer join (select id, value as type_3 from enumeration_value) as tbl3
    on tbl3.id = sub_container.type_2_id
  natural join 
    (select instance_type, instance_id from
  (select instance.id as instance_id, instance_type_id
  from instance left outer join archival_object
    on instance.archival_object_id = archival_object.id
  where instance.resource_id = #{@resource_id} or archival_object.root_record_id = #{@resource_id}) 
  as tbl4
    join (select id, value as instance_type from enumeration_value) as tbl5
    on tbl4.instance_type_id = tbl5.id) as instances"
  end
end
