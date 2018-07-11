class AccessionSubjectsNamesClassificationsListReport < AbstractReport

  register_report

  def template
    'accession_subjects_names_classifications_list_report.erb'
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(:restrictions_apply, :restrictionsApply),
             Sequel.as(:access_restrictions, :accessRestrictions),
             Sequel.as(:access_restrictions_note, :accessRestrictionsNote),
             Sequel.as(:use_restrictions, :useRestrictions),
             Sequel.as(:use_restrictions_note, :useRestrictionsNote),
             Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :containerSummary),
             Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accessionProcessed),
             Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accessionProcessedDate),
             Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType),
             Sequel.as(Sequel.lit('GetAccessionRightsTransferred(id)'), :rightsTransferred),
             Sequel.as(Sequel.lit('GetAccessionRightsTransferredNote(id)'), :rightsTransferredNote)).
       filter(:repo_id => @repo_id)
  end

end
