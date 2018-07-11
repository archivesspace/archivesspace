class LargeTreeDigitalObject

  def root(response, root_record)
    response['digital_object_type'] = root_record.digital_object_type
    response['file_uri_summary'] = root_record.file_version.map {|file_version|
      file_version[:file_uri]
    }.join(", ")

    response
  end

  def node(response, node_record)
    response
  end

  def waypoint(response, record_ids)
    file_uri_by_digital_object_component = {}

    DigitalObjectComponent
      .filter(:digital_object_component__id => record_ids)
      .where(Sequel.~(:digital_object_component__label => nil))
      .select(Sequel.as(:digital_object_component__id, :id),
              Sequel.as(:digital_object_component__label, :label))
      .each do |row|
      id = row[:id]
      result_for_record = response.fetch(record_ids.index(id))

      result_for_record['label'] = row[:label]
    end

    ASDate
      .left_join(Sequel.as(:enumeration_value, :date_type), :id => :date__date_type_id)
      .left_join(Sequel.as(:enumeration_value, :date_label), :id => :date__label_id)
      .filter(:digital_object_component_id => record_ids)
      .select(:digital_object_component_id,
              Sequel.as(:date_type__value, :type),
              Sequel.as(:date_label__value, :label),
              :expression,
              :begin,
              :end)
      .each do |row|

      id = row[:digital_object_component_id]

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

    FileVersion.filter(:digital_object_component_id => record_ids)
      .select(:digital_object_component_id,
              :file_uri)
      .each do |row|
      id = row[:digital_object_component_id]

      file_uri_by_digital_object_component[id] ||= []
      file_uri_by_digital_object_component[id] << row[:file_uri]
    end

    file_uri_by_digital_object_component.each do |id, file_uris|
      result_for_record = response.fetch(record_ids.index(id))
      result_for_record['file_uri_summary'] = file_uris.compact.join(", ")
    end

    response
  end

end
