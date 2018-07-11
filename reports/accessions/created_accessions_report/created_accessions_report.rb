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
    ['id', 'identifier', 'title', 'accession_date']
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'accession_date' => proc {|record| record[:accession_date].strftime("%Y-%m-%d")},
    }
  end

  def query
    db[:accession].where(:accession_date => (@from..@to)).order(Sequel.asc(:accession_date)).filter( :repo_id => @repo_id )
  end

end
