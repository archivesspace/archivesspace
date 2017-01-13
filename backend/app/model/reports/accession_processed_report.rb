class AccessionProcessedReport < AbstractReport

  register_report({
                    :uri_suffix => "accession_processed_report",
                    :description => "Displays only those accession(s) that have been processed based on the date processed field. Report contains accession number, linked resources, title, extent, cataloged, date processed, a count of the number of records selected with a date processed, and the total extent number for those records with date processed.",
                  })

  def title
    "Processed Accessions"
  end

  def template
    'accession_processed_report.erb'
  end

  def processor
    {
      'accessionId' => proc {|record| record[:accessionId]},
      'repo' => proc {|record| record[:repo]},
      'accessionNumber' => proc {|record| record[:accessionNumber]},
      'title' => proc {|record| record[:title]},
      'accessionDate' => proc {|record| record[:accessionDate]},
      'containerSummary' => proc {|record| record[:containerSummary]},
      'accessionProcessed' => proc {|record| record[:accessionProcessed]},
      'accessionProcessedDate' => proc {|record| record[:accessionProcessedDate]},
      'cataloged' => proc {|record| record[:cataloged]},
      'extentNumber' => proc {|record| record[:extentNumber]},
      'extentType' => proc {|record| record[:extentType]},
    }
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :containerSummary),
             Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accessionProcessed),
             Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accessionProcessedDate),
             Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end

  # Number of Records Reviewed
  def total_count
    @total_count ||= self.query.count
  end

  # Processed Accessions
  def total_processed
    @total_processed ||= db.from(self.query).where(:accessionProcessed => 1).count
  end

  # Accessioned Between - From Date
  def from_date
    @from_date ||= self.query.min(:accession_date)
  end

  # Accessioned Between - To Date
  def to_date
    @to_date ||= self.query.max(:accession_date)
  end

  #Total Extent of Processed Accessions
  def total_extent_of_processed
    @total_extent_of_processed ||= db.from(self.query).where(:accessionProcessed => 1).sum(:extentNumber)
  end
end
