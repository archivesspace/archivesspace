class AccessionDeaccessionsListReport < AbstractReport
  register_report

  def query
    results = db[:accession]
              .select(Sequel.as(:id, :accession_id),
                      Sequel.as(:identifier, :accession_number),
                      Sequel.as(:title, :accession_title),
                      Sequel.as(:accession_date, :accession_date),
                      Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :container_summary),
                      Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extent_number),
                      Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extent_type))
              .filter(repo_id: @repo_id)
    get_accessioned_between(results)
    get_total_extent(results)
    info['total_deaccessions_extent'] = 0
    info[:number_of_records] = results.count
    results
  end

  def fix_row(row)
    ReportUtils.fix_extent_format(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    deaccessions = AccessionDeaccessionsSubreport.new(self, row[:accession_id])
    row[:deaccessions] = deaccessions.get
    info['total_deaccessions_extent'] += deaccessions.total_extent unless deaccessions.total_extent.nil?
    row.delete(:accession_id)
  end

  def after_tasks
    ReportUtils.fix_decimal_format(info, %w[total_extent total_deaccessions_extent])
  end

  # Accessioned Between
  def get_accessioned_between(results)
    from_date = results.min(:accession_date)
    to_date = results.max(:accession_date)
    info['accessioned_between'] = "#{from_date} & #{to_date}"
  end

  # Total Extent of Accessions
  def get_total_extent(results)
    info['total_extent'] = db.from(results).sum(:extent_number)
  end

  def identifier_field
    :accession_number
  end

  def page_break
    false
  end
end
