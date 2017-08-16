class AssessmentListReport < AbstractReport

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

  def template
    "assessment_list_report.erb"
  end

  def total_count
    query.count
  end

  def query
    RequestContext.open(:repo_id => repo_id) do
      Assessment.this_repo
        .filter(:survey_begin => (@from..@to))
        .order(Sequel.asc(:survey_begin))
    end
  end

  BATCH_SIZE = 5

  def each_assessment
    RequestContext.open(:repo_id => repo_id) do
      query.each_slice(BATCH_SIZE).each do |objs|
        URIResolver.resolve_references(Assessment.sequel_to_jsonmodel(objs),
                                       ['records', 'surveyed_by'])
          .each do |assessment_json|
          yield assessment_json
        end
      end
    end
  end

end


