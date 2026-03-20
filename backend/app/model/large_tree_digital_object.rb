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

    # +label+ is a translatable field stored in +digital_object_component_mlc+.
    # Resolve the language using the same fallback chain as MultilingualContent.
    lang = RequestContext.get(:language_of_description)
    unless lang
      db = DigitalObjectComponent.db
      lang_enum   = db[:enumeration].filter(:name => 'language_iso639_2').get(:id)
      script_enum = db[:enumeration].filter(:name => 'script_iso15924').get(:id)
      lang_id     = db[:enumeration_value]
                      .filter(:enumeration_id => lang_enum, :value => AppConfig[:mlc_default_language]).get(:id)
      script_id   = db[:enumeration_value]
                      .filter(:enumeration_id => script_enum, :value => AppConfig[:mlc_default_script]).get(:id)
      lang = (lang_id && script_id) ? { language_id: lang_id, script_id: script_id } : nil
    end

    if lang
      DigitalObjectComponent.db[:digital_object_component_mlc]
        .filter(:digital_object_component_id => record_ids,
                :language_id => lang[:language_id],
                :script_id   => lang[:script_id])
        .where(Sequel.~(:label => nil))
        .select(:digital_object_component_id, :label)
        .each do |row|
          id = row[:digital_object_component_id]
          result_for_record = response.fetch(record_ids.index(id))
          result_for_record['label'] = row[:label]
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
