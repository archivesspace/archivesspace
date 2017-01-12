class AccessionsRightsTransferredReport < AbstractReport

  register_report({
                    :uri_suffix => "accessions_rights_transferred_report",
                    :description => "Displays only those accession(s) for which rights have been transferred. Report contains accession number, linked resources, title, extent, cataloged, date processed, access restrictions, use restrictions, rights transferred and a count of the number of records selected with rights transferred.",
                  })

  def title
    "Accessions with rights transferred"
  end

  def template
    '_accessions_rights_transferred_report.erb'
  end

  def headers
    ['accessionId', 'repo_id', 'accessionNumber', 'title', 'accessionDate',
     'restrictionsApply', 'accessRestrictions', 'accessRestrictionsNote',
     'useRestrictions', 'useRestrictionsNote', 'containerSummary', 'accessionProcessedDate',
     'cataloged', 'extentNumber', 'extentType', 'rightsTransferred', 'rightsTransferredNote']
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record| ASUtils.json_parse(record[:accessionNumber]).compact.join('.')},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate].nil? ? '' : record[:accessionDate].strftime("%Y-%m-%d")},
      'restrictionsApply' => proc {|record| record[:restrictionsApply]},
      'accessRestrictions' => proc {|record| record[:accessRestrictions]},
      'accessRestrictionsNote' => proc {|record| record[:accessRestrictionsNote]},
      'useRestrictions' => proc {|record| record[:useRestrictions]},
      'useRestrictionsNote' => proc {|record| record[:useRestrictionsNote]},
      'containerSummary' => proc {|record| record[:containerSummary]},
      'accessionProcessedDate' => proc {|record| record[:accessionProcessedDate].nil? ? '' : record[:accessionProcessedDate].strftime("%Y-%m-%d")}, 
      'cataloged' => proc {|record| record[:cataloged]},
      'extentNumber' => proc {|record| record[:extentNumber]},
      'extentType' => proc {|record| record[:extentType]},
      'rightsTransferred' => proc {|record| record[:rightsTransferred]},
      'rightsTransferredNote' => proc {|record| record[:rightsTransferredNote]},
    }
  end

  def query
    db[sql]
  end


  def extra_queries
    {
      'Number of Records Reviewed' => proc { self.query.count },
      'Accessions with Rights Transferred' => proc {
        db["select count(*) as count from (#{sql}) as data where rightsTransferred = 1"].first[:count]
      }
    }
  end


  private

  def sql
    <<EOS
SELECT
    accession.id AS accessionId,
    accession.repo_id AS repo_id,
    accession.identifier AS accessionNumber,
    accession.title AS title,
    accession.accession_date AS accessionDate,
    accession.restrictions_apply AS restrictionsApply,
    accession.access_restrictions AS accessRestrictions,
    accession.access_restrictions_note AS accessRestrictionsNote,
    accession.use_restrictions AS useRestrictions,
    accession.use_restrictions_note AS useRestrictionsNote,
    GetAccessionContainerSummary(accession.id) AS containerSummary,
    GetAccessionProcessedDate(accession.id) AS accessionProcessedDate,
    GetAccessionCataloged(accession.id) AS cataloged,
    GetAccessionExtent(accession.id) AS extentNumber,
    GetAccessionExtentType(accession.id) AS extentType,
    GetAccessionRightsTransferred(accession.id) AS rightsTransferred,
    GetAccessionRightsTransferredNote(accession.id) AS rightsTransferredNote
FROM
    accession accession
EOS
  end

end
