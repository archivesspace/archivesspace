class LargeTreeDigitalObject

  def initialize(root_record)
    entry = root_record.language_and_script_of_description.find { |ld| ld.is_primary == 1 }
    @primary_language = entry ? { language_id: entry[:language_id], script_id: entry[:script_id] } : nil
  end

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

    ids_without_label = record_ids.dup

    [RequestContext.requested_description_language, @primary_language, RequestContext.default_description_language].compact.uniq.each do |lang|
      break if ids_without_label.empty?

      DigitalObjectComponent.db[:digital_object_component_mlc]
        .filter(:digital_object_component_id => ids_without_label,
                :language_id => lang[:language_id],
                :script_id   => lang[:script_id])
        .where(Sequel.~(:label => nil))
        .select(:digital_object_component_id, :label)
        .each do |row|
          id = row[:digital_object_component_id]
          result_for_record = response.fetch(record_ids.index(id))
          result_for_record['label'] = row[:label]
          ids_without_label.delete(id)
        end
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
