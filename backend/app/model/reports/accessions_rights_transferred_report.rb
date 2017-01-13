class AccessionsRightsTransferredReport < AbstractReport

  register_report({
                    :uri_suffix => "accessions_rights_transferred_report",
                    :description => "Displays only those accession(s) for which rights have been transferred. Report contains accession number, linked resources, title, extent, cataloged, date processed, access restrictions, use restrictions, rights transferred and a count of the number of records selected with rights transferred.",
                  })

  def title
    "Accessions with rights transferred"
  end

  def template
    'accessions_rights_transferred_report.erb'
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record| record[:accessionNumber]},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate]},
      'restrictionsApply' => proc {|record| record[:restrictionsApply]},
      'accessRestrictions' => proc {|record| record[:accessRestrictions]},
      'accessRestrictionsNote' => proc {|record| record[:accessRestrictionsNote]},
      'useRestrictions' => proc {|record| record[:useRestrictions]},
      'useRestrictionsNote' => proc {|record| record[:useRestrictionsNote]},
      'containerSummary' => proc {|record| record[:containerSummary]},
      'accessionProcessedDate' => proc {|record| record[:accessionProcessedDate]}, 
      'cataloged' => proc {|record| record[:cataloged]},
      'extentNumber' => proc {|record| record[:extentNumber]},
      'extentType' => proc {|record| record[:extentType]},
      'rightsTransferred' => proc {|record| record[:rightsTransferred]},
      'rightsTransferredNote' => proc {|record| record[:rightsTransferredNote]},
    }
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
             Sequel.as(Sequel.lit('GetAccessionRightsTransferredNote(id)'), :rightsTransferredNote))
  end

  # Number of Records Reviewed
  def total_count
    @total_count ||= self.query.count
  end

  # Accessions with Rights Transferred
  def total_transferred
    @total_transferred ||= db.from(self.query).where(:rightsTransferred => 1).count
  end

end
