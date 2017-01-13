class RepositoryReport < AbstractReport
  register_report({
                    :uri_suffix => "repository_report",
                    :description => "Report on repository records"
                  })

  def title
    "Repository Report"
  end

  def headers
    Repository.columns 
  end

  def processor
    {
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
    }
  end

  def query
    db[:repository]
  end

end
