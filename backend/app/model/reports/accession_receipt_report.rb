class AccessionReceiptReport < AbstractReport

  register_report({
                    :uri_suffix => "accession_receipt_report",
                    :description => "Displays a receipt indicating accessioning of materials. Report contains accession number, title, extent, accession date, and repository.",
                  })

  def title
    "Accession Receipt Report"
  end

  def template
    'accession_receipt_report.erb'
  end

  def query
    db[:accession].
      select(Sequel.as(:id, :accessionId),
             Sequel.as(:repo_id, :repo_id),
             Sequel.as(:identifier, :accessionNumber),
             Sequel.as(:title, :title),
             Sequel.as(:accession_date, :accessionDate),
             Sequel.as(Sequel.lit('GetAccessionContainerSummary(id)'), :containerSummary),
             Sequel.as(Sequel.lit('GetRepositoryName(repo_id)'), :repositoryName),
             Sequel.as(Sequel.lit('GetAccessionExtent(id)'), :extentNumber),
             Sequel.as(Sequel.lit('GetAccessionExtentType(id)'), :extentType))
  end

end
