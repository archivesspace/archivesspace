class UnprocessedAccessionsReport < AbstractReport
  register_report({
                    :uri => "/reports/unprocessed_accessions",
                    :description => "Report on all unprocessed accessions",
                  })

  def initialize(params)
    super
  end

  def headers
    ['id', 'title']
  end

  def query(db)
    db[:accession].all
  end

end