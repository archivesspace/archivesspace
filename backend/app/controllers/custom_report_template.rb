class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/custom_report_templates')
    .description("Create a Custom Report Template")
    .params(["custom_report_template", JSONModel(:custom_report_template), "The record to create", :body => true],
        ["repo_id", :repo_id])
    .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
          -H "X-ArchivesSpace-Session: $SESSION" \\
          -d '{
                "lock_version": 0,
                "name": "A New Custom Template",
                "description": "A custom report template returning old accessions sorted by title.",
                "data": "{\"fields\":{\"access_restrictions\":{\"value\":\"true\"},\"accession_date\":{\"include\":\"1\",\"range_start\":\"2011-01-01\",\"range_end\":\"2019-12-31\"},\"publish\":{\"value\":\"true\"},\"restrictions_apply\":{\"value\":\"true\"},\"title\":{\"include\":\"1\"},\"use_restrictions\":{\"value\":\"true\"},\"create_time\":{\"range_start\":\"\",\"range_end\":\"\"},\"user_mtime\":{\"range_start\":\"\",\"range_end\":\"\"}},\"sort_by\":\"title\",\"custom_record_type\":\"accession\"}",
                "limit": 100,
                "jsonmodel_type": "custom_report_template",
                "repository": {
                    "ref": "/repositories/2"
                }
              }' \\
          "http://localhost:8089/repositories/2/custom_report_templates"
      SHELL
    end
    .permissions(['manage_custom_report_templates'])
    .returns([200, :created]) \
  do
    handle_create(CustomReportTemplate, params[:custom_report_template])
  end

  Endpoint.post('/repositories/:repo_id/custom_report_templates/:id')
    .description("Update a CustomReportTemplate")
    .params(["id", :id],
            ["custom_report_template", JSONModel(:custom_report_template), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .example('shell') do
      <<~SHELL
        curl -H 'Content-Type: application/json' \\
          -H "X-ArchivesSpace-Session: $SESSION" \\
          -d '{
                "lock_version": 0,
                "name": "A Newer Custom Template",
                "description": "A custom report template returning old accessions sorted by title.",
                "data": "{\"fields\":{\"access_restrictions\":{\"value\":\"true\"},\"accession_date\":{\"include\":\"1\",\"range_start\":\"2011-01-01\",\"range_end\":\"2019-12-31\"},\"publish\":{\"value\":\"true\"},\"restrictions_apply\":{\"value\":\"true\"},\"title\":{\"include\":\"1\"},\"use_restrictions\":{\"value\":\"true\"},\"create_time\":{\"range_start\":\"\",\"range_end\":\"\"},\"user_mtime\":{\"range_start\":\"\",\"range_end\":\"\"}},\"sort_by\":\"title\",\"custom_record_type\":\"accession\"}",
                "limit": 100,
                "jsonmodel_type": "custom_report_template",
                "repository": {
                    "ref": "/repositories/2"
                }
              }' \\
          "http://localhost:8089/repositories/2/custom_report_templates/1"
      SHELL
    end
    .permissions(['manage_custom_report_templates'])
    .returns([200, :updated]) \
  do
    handle_update(CustomReportTemplate, params[:id], params[:custom_report_template])
  end

  Endpoint.get('/repositories/:repo_id/custom_report_templates')
    .description("Get a list of Custom Report Templates")
    .params(["repo_id", :repo_id])
    .example('shell') do
      <<~SHELL
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
          "http://localhost:8089/repositories/2/custom_report_templates?page=1"
      SHELL
    end
    .paginated(true)
    .sufficient_permissions(['create_job', 'manage_custom_report_templates'])
    .returns([200, "[(:custom_report_template)]"]) \
  do
    handle_listing(CustomReportTemplate, params)
  end


  Endpoint.get('/repositories/:repo_id/custom_report_templates/:id')
    .description("Get a Custom Report Template by ID")
    .params(["id", :id],
        ["resolve", :resolve],
        ["repo_id", :repo_id])
    .example('shell') do
      <<~SHELL
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
          "http://localhost:8089/repositories/2/custom_report_templates/1"
      SHELL
    end
    .permissions(['create_job'])
    .returns([200, "(:custom_report_template)"]) \
  do
    json = CustomReportTemplate.to_jsonmodel(params[:id])

    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.delete('/repositories/:repo_id/custom_report_templates/:id')
    .description("Delete an Custom Report Template")
    .params(["id", :id],
        ["repo_id", :repo_id])
    .example('shell') do
      <<~SHELL
        curl -H "X-ArchivesSpace-Session: $SESSION" \\
          -X DELETE \\
          "http://localhost:8089/repositories/2/custom_report_templates/1"
      SHELL
    end
    .permissions(['manage_custom_report_templates'])
    .returns([200, :deleted]) \
  do
    handle_delete(CustomReportTemplate, params[:id])
  end
end
