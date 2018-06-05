class AccessionSubjectsNamesClassificationsListReport < AbstractReport

  register_report

  def query
    db[:accession].
      select(Sequel.as(:id, :id),
             Sequel.as(:identifier, :accession_number),
             Sequel.as(:title, :accession_title),
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
             Sequel.as(Sequel.lit('GetAccessionRightsTransferredNote(id)'), :rights_transferred_note)).
       filter(:repo_id => @repo_id)
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :accession_number)
    ReportUtils.fix_extent_format(row)
    row[:names] = AccessionNamesSubreport.new(self, row[:id]).get
    row[:subjects] = AccessionSubjectsSubreport.new(self, row[:id]).get
    row[:classifications] = AccessionClassificationsSubreport.new(self, row[:id]).get
    row.delete(:id)
  end

end
