class AccessionRightsTransferredReport < AbstractReport
  register_report

  def template
    'accession_rights_transferred_report.erb'
  end

  def query
    array = []
    db[:accession]
      .select(Sequel.as(:id, :accession_id),
              Sequel.as(:repo_id, :repo_id),
              Sequel.as(:identifier, :accession_number),
              Sequel.as(:title, :title),
              Sequel.as(:accession_date, :accession_date),
              Sequel.as(:restrictions_apply, :restrictions_apply),
              Sequel.as(:access_restrictions, :access_restrictions),
              Sequel.as(:access_restrictions_note, :access_restrictions_note),
              Sequel.as(:use_restrictions, :use_restrictions),
              Sequel.as(:use_restrictions_note, :use_restrictions_note),
              Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :container_summary),
              Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accession_processed),
              Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accession_processed_date),
              Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
              Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extent_number),
              Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extent_type),
              Sequel.as(Sequel.lit('GetAccessionRightsTransferred(id)'), :rights_transferred),
              Sequel.as(Sequel.lit('GetAccessionRightsTransferredNote(id)'), :rights_transferred_note))
      .filter(repo_id: @repo_id)
      .where(Sequel.~(Sequel.lit('GetAccessionRightsTransferred(id)') => 0))
    .each do |result|
      row = result.to_hash
      ReportUtils.fix_extent_format(row)
      ReportUtils.fix_identifier_format(row, :accession_number)
    end
  end

  # Accessions with Rights Transferred
  def total_transferred(results)
    @total_transferred ||= db.from(results).where(rightsTransferred: 1).count
  end
end
