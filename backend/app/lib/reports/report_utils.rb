module ReportUtils

  def self.fix_extent_format(row)
    row[:extent] = "#{row[:extent_number].round(2)} #{row[:extent_type]}"
    row.delete(:extent_type)
    row.delete(:extent_number)
  end

  def self.fix_boolean_fields(row, fields)
    fields.each do |field|
      row[field] = row[field] == 1 ? 'Yes' : 'No'
    end
  end

  def self.fix_identifer_format(row, field_name = :identifier)
    row[field_name] = ASUtils.json_parse(row[field_name]).compact.join('.')
  end
end