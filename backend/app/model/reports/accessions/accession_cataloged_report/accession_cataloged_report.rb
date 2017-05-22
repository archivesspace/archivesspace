class AccessionCatalogedReport < AbstractReport

  register_report

  def template
    'accession_cataloged_report.erb'
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


  # TODO: subreport for linked resources

  # Number of Records Reviewed
  def total_count
    @totalCount ||= self.query.count
  end

  # Cataloged Accessions
  def cataloged_count
    @catalogedCount ||= db.from(self.query).where(:cataloged => 1).count
  end

  # Total Extent of Cataloged Accessions
  def total_extent
    @totalExtent ||= db.from(self.query).where(:cataloged => 1).sum(:extentNumber)
  end
end
