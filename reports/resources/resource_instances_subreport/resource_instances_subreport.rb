class ResourceInstancesSubreport < AbstractSubreport

  register_subreport('instance', ['resource'])

  def initialize(parent_report, resource_id)
    super(parent_report)
    @resource_id = resource_id
  end

  def query
    results = db.fetch(query_string)
    sorted = {}
    results.each do |result|
      top_id = result[:top_container_id]
      top_id ||= -1
      unless sorted.has_key?(top_id)
        sorted[top_id] = {}
        if top_id == -1
          sorted[top_id][:indicator] = 'Digital Object Instances'
        else
          sorted[top_id][:type] = result[:type_1]
          sorted[top_id][:indicator] = result[:indicator_1]
        end
        ReportUtils.get_enum_values(sorted[top_id], [:type])
        ReportUtils.fix_container_indicator(sorted[top_id])
        sorted[top_id][:container_profile] = query_profiles(top_id)
        sorted[top_id][:instances] = []
        sorted[top_id][:id] = top_id
      end
      result.delete(:top_container_id)
      result.delete(:indicator_1)
      result.delete(:type_1)
      sorted[top_id][:instances].push(result)
    end
    sorted.values
  end

  def query_string
    "select distinct
      top_container.id as top_container_id,
      top_container.type_id as type_1,
      top_container.indicator as indicator_1,
      sub_container.type_2_id as type_2,
      sub_container.indicator_2 as indicator_2,
      sub_container.type_3_id as type_3,
      sub_container.indicator_3 as indicator_3,
      digital_objects.digital_object as digital_object,
      instances.instance_type_id as instance_type,
      instances.is_representative

    from

      (select instance.id, instance_type_id, is_representative
      from instance
        left outer join archival_object
          on instance.archival_object_id = archival_object.id
      where instance.resource_id = #{db.literal(@resource_id)}
        or archival_object.root_record_id
        = #{db.literal(@resource_id)}) as instances

      left outer join sub_container on instances.id = sub_container.instance_id
      
      left outer join top_container_link_rlshp
        on sub_container.id = top_container_link_rlshp.sub_container_id
      
      left outer join top_container
        on top_container.id = top_container_link_rlshp.top_container_id

      left outer join
        (select
          instance_do_link_rlshp.instance_id,
          group_concat(digital_object.title separator '; ') as digital_object
        from instance_do_link_rlshp, digital_object
        where instance_do_link_rlshp.digital_object_id = digital_object.id
        group by instance_do_link_rlshp.instance_id) as digital_objects
      on digital_objects.instance_id = instances.id"
  end

  def fix_row(row)
    row[:instances].each do |instance|
      ReportUtils.get_enum_values(instance, [:type_2, :type_3, :instance_type])
      ReportUtils.fix_container_indicator(instance, 2)
      ReportUtils.fix_container_indicator(instance, 3)
      ReportUtils.fix_boolean_fields(instance, [:is_representative])
    end
    row[:instances].push(code) if format == 'pdf' || format == 'html'
    row.delete(:id)
  end

  def query_profiles(container_id)
    query_string = "select name from
    container_profile join top_container_profile_rlshp
      on container_profile.id = container_profile_id
    where top_container_id = #{db.literal(container_id)}"
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

  def self.field_name
    'instance'
  end
end
