class AccessionProductionReport < AbstractReport

  register_report

  def template
    'accession_production_report.erb'
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(Sequel.lit('GetAccessionProcessed(id)'), :accessionProcessed),
             Sequel.as(Sequel.lit('GetAccessionProcessedDate(id)'), :accessionProcessedDate),
             Sequel.as(Sequel.lit('GetAccessionCataloged(id)'), :cataloged),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end

  # Accessioned Between - From Date
  def from_date
    @from_date ||= self.query.min(:accession_date)
  end

  # Accessioned Between - To Date
  def to_date
    @to_date ||= self.query.max(:accession_date)
  end

  # Total Extent of Selected Accessions
  def total_extent
    @total_extent ||= db.from(self.query).sum(:extentNumber)
  end

  # Number of Records Selected
  def total_count
    @total_count ||= self.query.count
  end

  # Total Extent of Cataloged Accessions
  def total_extent_of_cataloged
    @total_extent_of_cataloged ||= db.from(self.query).
                                      filter(:cataloged => 1).
                                      sum(:extentNumber)
  end

  # Total Extent of Cataloged Accessions
  def total_extent_of_processed
    @total_extent_of_processed ||= db.from(self.query).
                                      filter(:accessionProcessed => 1).
                                      sum(:extentNumber)
  end

end
