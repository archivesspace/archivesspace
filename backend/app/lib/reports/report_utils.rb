module ReportUtils
  def self.fix_extent_format(row)
    row[:extent] = "#{format('%.2f', row[:extent_number].to_s)} #{row[:extent_type]}"
    row.delete(:extent_type)
    row.delete(:extent_number)
  end

  def self.fix_boolean_fields(row, fields)
    fields.each do |field|
      row[field] = row[field] == 0 || row[field] == '0' ? 'No' : 'Yes'
    end
  end

  def self.fix_identifier_format(row, field_name = :identifier)
    row[field_name] = ASUtils.json_parse(row[field_name]).compact.join('.') if row[field_name]
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
end
