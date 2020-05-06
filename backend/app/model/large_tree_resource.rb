class LargeTreeResource

  def root(response, root_record)
    response['level'] = root_record.other_level || root_record.level

    # Collect all container data
    Instance
      .left_join(:sub_container, :sub_container__instance_id => :instance__id)
      .left_join(:top_container_link_rlshp, :sub_container_id => :sub_container__id)
      .left_join(:top_container, :id => :top_container_link_rlshp__top_container_id)
      .left_join(Sequel.as(:enumeration_value, :top_container_type), :id => :top_container__type_id)
      .left_join(Sequel.as(:enumeration_value, :type_2), :id => :sub_container__type_2_id)
      .left_join(Sequel.as(:enumeration_value, :type_3), :id => :sub_container__type_3_id)
      .left_join(Sequel.as(:enumeration_value, :instance_type), :id => :instance__instance_type_id)
      .filter(:resource_id => root_record.id)
      .select(Sequel.as(:instance_type__value, :instance_type),
              Sequel.as(:top_container_type__value, :top_container_type),
              Sequel.as(:top_container__indicator, :top_container_indicator),
              Sequel.as(:top_container__barcode, :top_container_barcode),
              Sequel.as(:type_2__value, :type_2),
              Sequel.as(:sub_container__indicator_2, :indicator_2),
              Sequel.as(:sub_container__barcode_2, :barcode_2),
              Sequel.as(:type_3__value, :type_3),
              Sequel.as(:sub_container__indicator_3, :indicator_3))
    .each do |row|
        response['containers'] ||= []

        container_data = {}
        container_data['instance_type'] = row[:instance_type] if row[:instance_type]
        container_data['top_container_type'] = row[:top_container_type] if row[:top_container_type]
        container_data['top_container_indicator'] = row[:top_container_indicator] if row[:top_container_indicator]
        container_data['top_container_barcode'] = row[:top_container_barcode] if row[:top_container_barcode]
        container_data['type_2'] = row[:type_2] if row[:type_2]
        container_data['indicator_2'] = row[:indicator_2] if row[:indicator_2]
        container_data['barcode_2'] = row[:barcode_2] if row[:barcode_2]
        container_data['type_3'] = row[:type_3] if row[:type_3]
        container_data['indicator_3'] = row[:indicator_3] if row[:indicator_3]

        response['containers'] << container_data
    end
    
    response
  end

  def node(response, node_record)
    response
  end

  def waypoint(response, record_ids)
    # Load the instance type and record level
    ArchivalObject
      .left_join(Sequel.as(:enumeration_value, :level_enum), :id => :archival_object__level_id)
      .filter(:archival_object__id => record_ids)
      .select(Sequel.as(:archival_object__id, :id),
              Sequel.as(:level_enum__value, :level),
              Sequel.as(:archival_object__other_level, :other_level))
      .each do |row|
      id = row[:id]
      result_for_record = response.fetch(record_ids.index(id))

      result_for_record['level'] = row[:other_level] || row[:level]
    end

    ASDate
      .left_join(Sequel.as(:enumeration_value, :date_type), :id => :date__date_type_id)
      .left_join(Sequel.as(:enumeration_value, :date_label), :id => :date__label_id)
      .filter(:archival_object_id => record_ids)
      .select(:archival_object_id,
              Sequel.as(:date_type__value, :type),
              Sequel.as(:date_label__value, :label),
              :expression,
              :begin,
              :end)
      .each do |row|

      id = row[:archival_object_id]

      result_for_record = response.fetch(record_ids.index(id))
      result_for_record['dates'] ||= []

      date_data = {}
      date_data['type'] = row[:type] if row[:type]
      date_data['label'] = row[:label] if row[:label]
      date_data['expression'] = row[:expression] if row[:expression]
      date_data['begin'] = row[:begin] if row[:begin]
      date_data['end'] = row[:end] if row[:end]

      result_for_record['dates'] << date_data
    end

    # Display container information
    Instance
      .left_join(:sub_container, :sub_container__instance_id => :instance__id)
      .left_join(:top_container_link_rlshp, :sub_container_id => :sub_container__id)
      .left_join(:top_container, :id => :top_container_link_rlshp__top_container_id)
      .left_join(Sequel.as(:enumeration_value, :top_container_type), :id => :top_container__type_id)
      .left_join(Sequel.as(:enumeration_value, :type_2), :id => :sub_container__type_2_id)
      .left_join(Sequel.as(:enumeration_value, :type_3), :id => :sub_container__type_3_id)
      .left_join(Sequel.as(:enumeration_value, :instance_type), :id => :instance__instance_type_id)
      .filter(:archival_object_id => record_ids)
      .select(:archival_object_id,
              Sequel.as(:instance_type__value, :instance_type),
              Sequel.as(:top_container_type__value, :top_container_type),
              Sequel.as(:top_container__indicator, :top_container_indicator),
              Sequel.as(:top_container__barcode, :top_container_barcode),
              Sequel.as(:type_2__value, :type_2),
              Sequel.as(:sub_container__indicator_2, :indicator_2),
              Sequel.as(:sub_container__barcode_2, :barcode_2),
              Sequel.as(:type_3__value, :type_3),
              Sequel.as(:sub_container__indicator_3, :indicator_3))
      .each do |row|
      id = row[:archival_object_id]

      result_for_record = response.fetch(record_ids.index(id))
      result_for_record['containers'] ||= []

      container_data = {}
      container_data['instance_type'] = row[:instance_type] if row[:instance_type]
      container_data['top_container_type'] = row[:top_container_type] if row[:top_container_type]
      container_data['top_container_indicator'] = row[:top_container_indicator] if row[:top_container_indicator]
      container_data['top_container_barcode'] = row[:top_container_barcode] if row[:top_container_barcode]
      container_data['type_2'] = row[:type_2] if row[:type_2]
      container_data['indicator_2'] = row[:indicator_2] if row[:indicator_2]
      container_data['barcode_2'] = row[:barcode_2] if row[:barcode_2]
      container_data['type_3'] = row[:type_3] if row[:type_3]
      container_data['indicator_3'] = row[:indicator_3] if row[:indicator_3]

      result_for_record['containers'] << container_data
    end

    response
  end

end
