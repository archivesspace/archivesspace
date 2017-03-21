class CreatedAccessionsReport < AbstractReport
  
  register_report({
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"]]
                  })

  def initialize(params, job, db)
    super
    from = params["from"] || Time.now.to_s
    to = params["to"] || Time.now.to_s
   
    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
  
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

  def query
    db[:accession].where(:create_time => (@from..@to)).order(Sequel.asc(:create_time))
  end

end
