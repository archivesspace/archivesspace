class UnprocessedAccessionsReport

  def initialize
  end

  def headers
    ['id', 'title']
  end

  def each
    DB.open do |db|
      db[:accession].all.each do |row|
        yield(Hash[headers.map { |h| [h, row[h.intern]]}])
      end
    end
  end

end