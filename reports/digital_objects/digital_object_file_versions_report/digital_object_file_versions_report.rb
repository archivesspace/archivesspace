class DigitalObjectFileVersionsReport < AbstractReport
  register_report

  def query
    results = db.fetch(query_string)
    info['total_count'] = results.count
    results
  end

  def query_string
    "select 
      digital_object.id as 'digital_object_id', 
      digital_object.digital_object_id as 'digital_object_identifier', 
      title as 'digital_object_title', 
      file_uri as 'digital_object_uri' 
      from digital_object 
      join file_version on digital_object.id = file_version.digital_object_id 
      where repo_id = #{db.literal(@repo_id)} and file_uri is not null"
  end

  def fix_row(row)
    row[:file_versions] = DigitalObjectFileVersionsListSubreport
                          .new(self, row[:id]).get_content
    row.delete(:id)
  end

  def page_break
    false
  end

  def identifier_field
    :identifier
  end
end
