class LargeTreeDigitalObject

  # FIXME: add: digital object type, file version summary
  #
  # summary - go through all file versions, get the file_uri and comma delimit them

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
