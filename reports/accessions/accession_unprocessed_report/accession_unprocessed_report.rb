class AccessionUnprocessedReport < AbstractReport

  register_report

  def template
    'accession_unprocessed_report.erb'
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
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType)).
       filter(:repo_id => @repo_id)
  end

  # Unprocessed Accessions
  def total_unprocessed
    @total_processed ||= db.from(self.query).where(Sequel.~(:accessionProcessed => 1)).count
  end

  # Accessioned Between - From Date
  def from_date
    @from_date ||= self.query.min(:accession_date)
  end

  # Accessioned Between - To Date
  def to_date
    @to_date ||= self.query.max(:accession_date)
  end

  #Total Extent of Unprocessed Accessions
  def total_extent_of_unprocessed
    @total_extent_of_processed ||= db.from(self.query).where(Sequel.~(:accessionProcessed => 1)).sum(:extentNumber)
  end
end
