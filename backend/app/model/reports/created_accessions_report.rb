class CreatedAccessionsReport

  def initialize(from, to)
    @from = from
    @to = to
  end

  def headers
    ['id', 'title', 'create_date', 'create_time']
  end

  def processor
    {
      'create_date' => proc {|record| record[:create_time].strftime("%Y-%m-%d")},
      'create_time' => proc {|record| record[:create_time].strftime("%H:%M:%S")}
    }
  end

  def query(db)
    db[:accession].where(:create_time => (@from..@to)).order(Sequel.asc(:create_time))
  end

  def each
    DB.open do |db|
      query(db).each do |row|
        yield(Hash[headers.map { |h|
          val = (processor.has_key?(h))?processor[h].call(row):row[h.intern]
          [h, val]
        }])
      end
    end
  end

end