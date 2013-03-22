class CreatedAccessionsReport

  def initialize(from, to)
    @from = DateTime.parse(from)
    @to = DateTime.parse(to)
  end

  def headers
    ['id', 'title', 'create_time']
  end

  def query(db)
    db[:accession].where(:create_time => (@from..@to)).order(Sequel.asc(:create_time))
  end

  def each
    DB.open do |db|
      query(db).each do |row|
        yield(Hash[headers.map { |h| [h, row[h.intern]]}])
      end
    end
  end

end