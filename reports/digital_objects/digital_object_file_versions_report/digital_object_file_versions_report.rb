class DigitalObjectFileVersionsReport < AbstractReport
  register_report

  def query
    results = db.fetch(query_string)
    info['total_count'] = results.count
    results
  end

  def query_string
    "select 
      id,
      digital_object_id as identifier,
      title as record_title
    from digital_object where repo_id = #{db.literal(@repo_id)}"
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
