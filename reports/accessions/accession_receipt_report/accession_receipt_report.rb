class AccessionReceiptReport < AbstractReport
  register_report

  def template
    'accession_receipt_report.erb'
  end

  def query
    db[:accession]
      .select(Sequel.as(:identifier, :accession_number),
              Sequel.as(:title, :accession_title),
              Sequel.as(:accession_date, :repository_date),
              Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :container_summary),
              Sequel.as(Sequel.lit('GetRepositoryName(repo_id)'), :repository),
              Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extent_number),
              Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extent_type))
      .filter(repo_id: @repo_id)
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.fix_extent_format(row)
  end

  def identifier_field
    :accession_number
  end

  def page_break
    false
  end
end
