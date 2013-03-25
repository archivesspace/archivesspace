class UnprocessedAccessionsReport < AbstractReport

  def initialize
    super
  end

  def headers
    ['id', 'title']
  end

  def query(db)
    db[:accession].all
  end

end