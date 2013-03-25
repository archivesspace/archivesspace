class CreatedAccessionsReport < AbstractReport

  def initialize(from, to)
    super
    @from = from
    @to = to
  end

  def title
    "Accessions created between #{@from.strftime("%Y-%m-%d")} and #{@to.strftime("%Y-%m-%d")}"
  end

  def headers
    ['id', 'identifier', 'title', 'create_date', 'create_time']
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'create_date' => proc {|record| record[:create_time].strftime("%Y-%m-%d")},
      'create_time' => proc {|record| record[:create_time].strftime("%H:%M:%S")}
    }
  end

  def query(db)
    db[:accession].where(:create_time => (@from..@to)).order(Sequel.asc(:create_time))
  end

end