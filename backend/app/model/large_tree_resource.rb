class LargeTreeResource

  def root(response, root_record)
    response['level'] = root_record.level

    unless root_record.instance.empty?
      response['type'] = root_record.instance[0].instance_type
    end

    response
  end

  def node(response, node_record)
    response
  end

  def waypoint(response, record_ids)
    # Load the instance type and record level
    ArchivalObject
      .left_join(Instance, :archival_object_id => :id)
      .left_join(Sequel.as(:enumeration_value, :type_enum), :id => :instance__instance_type_id)
      .left_join(Sequel.as(:enumeration_value, :level_enum), :id => :archival_object__level_id)
      .filter(:archival_object__id => record_ids)
      .select(Sequel.as(:archival_object__id, :id),
              Sequel.as(:type_enum__value, :type),
              Sequel.as(:level_enum__value, :level))
      .each do |row|
      id = row[:id]
      result_for_record = response.fetch(record_ids.index(id))

      result_for_record['type'] = row[:type] if row[:type]
      result_for_record['level'] = row[:level]
    end

    # Display container information
    Instance
      .join(:sub_container, :sub_container__instance_id => :instance__id)
      .join(:top_container_link_rlshp, :sub_container_id => :sub_container__id)
      .join(:top_container, :id => :top_container_link_rlshp__top_container_id)
      .join(Sequel.as(:enumeration_value, :top_container_type), :id => :top_container__type_id)
      .join(Sequel.as(:enumeration_value, :type_2), :id => :sub_container__type_2_id)
      .join(Sequel.as(:enumeration_value, :type_3), :id => :sub_container__type_3_id)
      .filter(:archival_object_id => record_ids)
      .select(:archival_object_id,
              Sequel.as(:top_container_type__value, :top_container_type),
              Sequel.as(:top_container__indicator, :top_container_indicator),
              Sequel.as(:type_2__value, :type_2),
              Sequel.as(:sub_container__indicator_2, :indicator_2),
              Sequel.as(:type_3__value, :type_3),
              Sequel.as(:sub_container__indicator_3, :indicator_3))
      .each do |row|
      id = row[:archival_object_id]

      result_for_record = response.fetch(record_ids.index(id))
      result_for_record['container'] = [
                                        [row[:top_container_type], row[:top_container_indicator]].join(": "),
                                        [row[:type_2], row[:indicator_2]].compact.join(": "),
                                        [row[:type_3], row[:indicator_3]].compact.join(": "),
                                       ].reject(&:empty?).join(", ")
    end

    response
  end

end
