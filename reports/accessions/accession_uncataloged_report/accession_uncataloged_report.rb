class AccessionUncatalogedReport < AbstractReport

  register_report

  def template
    'accession_uncataloged_report.erb'
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
             Sequel.as(Sequel.lit('GetAccessionCatalogedDate(id)'), :catalogedDate),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end


  # Number of Records Reviewed
  def total_count
    @totalCount ||= self.query.count
  end

  # Uncataloged Accessions
  def uncataloged_count
    @uncatalogedCount ||= db.from(self.query).where(Sequel.~(:cataloged => 1)).count
  end

  # Total Extent of Uncataloged Accessions
  def total_extent
    @totalExtent ||= db.from(self.query).where(Sequel.~(:cataloged => 1)).sum(:extentNumber)
  end
end
