class AccessionDeaccessionsListReport < AbstractReport

  register_report({
                    :uri_suffix => "accession_deaccessions_list_report",
                    :description => "Displays a list of accession record(s) and linked deaccession record(s). Report contains accession number, title, extent, accession date, container summary, cataloged, date processed, rights transferred, linked deaccessions and total extent of all deaccessions.",
                  })

  def title
    "Accessions Acquired and Linked Deaccession Records"
  end

  def template
    'accession_deaccessions_list_report.erb'
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :containerSummary),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end

  # Number of Records
  def total_count
    @total_count ||= self.query.count
  end

  # Accessioned Between - From Date
  def from_date
    @from_date ||= self.query.min(:accession_date)
  end

  # Accessioned Between - To Date
  def to_date
    @to_date ||= self.query.max(:accession_date)
  end

  # Total Extent of Accessions
  def total_extent
    @total_extent ||= db.from(self.query).sum(:extentNumber)
  end

  # Total Extent of Deaccessions
  def total_extent_of_deaccessions
    return @total_extent_of_deaccessions if @total_extent_of_deaccessions

    deaccessions = db[:deaccession].where(:accession_id => self.query.select(:id))
    deaccession_extents = db[:extent].where(:deaccession_id => deaccessions.select(:id))
    
    @total_extent_of_deaccessions = deaccession_extents.sum(:number)

    @total_extent_of_deaccessions
  end

end
