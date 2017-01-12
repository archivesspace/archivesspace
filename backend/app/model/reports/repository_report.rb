# FIXME add db and review scope_by_repo_id
class RepositoryReport < AbstractReport
  register_report({
                    :uri_suffix => "repository_report",
                    :description => "Report on repository records"
                  })

  def initialize(params, job)
    super
  end

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

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

  def query(db)
    db[:repository].where( :id => @repo_id)
  end

end
