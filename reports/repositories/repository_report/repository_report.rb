class RepositoryReport < AbstractReport
  register_report

  def headers
    Repository.columns 
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
    }
  end

  def query
    db[:repository].filter(:hidden => 0)
  end

end
