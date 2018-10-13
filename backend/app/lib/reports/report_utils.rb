module ReportUtils
  def self.fix_extent_format(row)
    row[:extent_number] = 0.0 unless row[:extent_number]
    begin
      row[:extent] = "#{format('%.2f', row[:extent_number].to_s)} #{row[:extent_type]}"
    rescue ArgumentError => e
      row[:extent] = "#{row[:extent_number]} #{row[:extent_type]}"
    end
    row.delete(:extent_type)
    row.delete(:extent_number)
  end

  def self.fix_boolean_fields(row, fields)
    fields.each do |field|
      next if row[field] == nil
      row[field] = row[field] == 0 || row[field] == '0' ? 'No' : 'Yes'
    end
  end

  def self.fix_identifier_format(row, field_name = :identifier)
    if row[field_name]
      identifiers = row[field_name].split(',,,')
    else
      identifiers = []
    end

    result = []

    identifiers.each do |identifier|
      result.push(ASUtils.json_parse(identifier).compact.join('.'))
    end

    row[field_name] = result.join(', ')
  end

  def self.fix_decimal_format(record, fields)
    fields.each do |field|
      record[field] = format('%.2f', record[field].to_s) if record[field]
    end
  end

  def self.fix_container_indicator(row, container_num = 1)
    if container_num == 1
      type_field = :type
      indicator_field = :indicator
      field = :container
    elsif container_num == 2
      type_field = :type_2
      indicator_field = :indicator_2
      field = :container_2
    else
      type_field = :type_3
      indicator_field = :indicator_3
      field = :container_3
    end

    row[field] = [row[type_field], row[indicator_field]].compact.join(' ')
    row.delete(type_field)
    row.delete(indicator_field)
    row[field] = nil if row[field] == ''
  end

  def self.get_enum_values(row, fields)
    fields.each do |field|
      next unless row[field]
      if row[field].is_a?(Integer)
        values = [row[field]]
      else
        values = row[field].split(', ')
      end

      results = []

      values.each do |value|
        begin
          enum_value = EnumerationValue.get_or_die(value)
          enumeration = enum_value.enumeration.name
          results.push(I18n.t("enumerations.#{enumeration}.#{enum_value.value}",
            :default => enum_value.value))
        rescue Exception => e
          results.push("Missing enum value: #{value}")
        end
      end

      row[field] = results.join(', ')
    end
  end

  def self.get_location_coordinate(row)
    coor_1 = [row[:coordinate_1_label], row[:coordinate_1_indicator]].compact.join(' ')
    coor_2 = [row[:coordinate_2_label], row[:coordinate_2_indicator]].compact.join(' ')
    coor_3 = [row[:coordinate_3_label], row[:coordinate_3_indicator]].compact.join(' ')
    coordinates = []
    coordinates.push(coor_1) if coor_1 != ''
    coordinates.push(coor_2) if coor_2 != ''
    coordinates.push(coor_2) if coor_2 != ''
    row[:location_in_room] = [coor_1, coor_2, coor_3].compact.join(', ')
    row.delete(:coordinate_1_label)
    row.delete(:coordinate_1_indicator)
    row.delete(:coordinate_2_label)
    row.delete(:coordinate_2_indicator)
    row.delete(:coordinate_3_label)
    row.delete(:coordinate_3_indicator)
  end

  def self.local_times(row, fields)
    fields.each do |field|
      next unless row[field]
      row[field] = row[field].localtime.strftime(
        '%Y-%m-%d %H:%M:%S')
    end
  end

  def self.normalize_label(label)
    label.strip.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/_+$/, '')
  end

  def self.fix_id(row)
    row[:record_id] = normalize_label(row[:linked_record_type].to_s) + '_' + row[:record_id].to_s
    row.delete(:linked_record_type)
  end

end
