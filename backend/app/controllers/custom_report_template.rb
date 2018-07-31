class ArchivesSpaceService < Sinatra::Base

	# Endpoint.post('/repositories/:repo_id/custom_report_templates')
	# 	.description("Create a Custom Report Template")
	# 	.params(["custom_report_template", JSONModel(:custom_report_template), "The record to create", :body => true],
	# 			["repo_id", :repo_id])
	# 	.permissions(['create_job'])
	# 	.returns([200, :created]) \
	# do
	# 	handle_create(CustomReportTemplate, params[:custom_report_template])
	# end

	# Endpoint.post('/repositories/:repo_id/custom_report_templates/:id')
	# 	.description("Update a CustomReportTemplate")
	# 	.params(["id", :id],
	# 	        ["custom_report_template", JSONModel(:custom_report_template), "The updated record", :body => true],
	# 	        ["repo_id", :repo_id])
	# 	.permissions(['create_job'])
	# 	.returns([200, :updated]) \
	# do
	# 	handle_update(CustomReportTemplate, params[:id], params[:custom_report_template])
	# end

	# Endpoint.get('/repositories/:repo_id/custom_report_templates')
	# 	.description("Get a list of Custom Report Templates")
	# 	.params(["repo_id", :repo_id])
	# 	.paginated(true)
	# 	.permissions(['create_job'])
	# 	.returns([200, "[(:custom_report_template)]"]) \
	# do
	# 	handle_listing(CustomReportTemplate, params)
	# end


	# Endpoint.get('/repositories/:repo_id/custom_report_templates/:id')
	# 	.description("Get a Custom Report Template by ID")
	# 	.params(["id", :id],
	# 			["resolve", :resolve],
	# 			["repo_id", :repo_id])
	# 	.permissions(['create_job'])
	# 	.returns([200, "(:custom_report_template)"]) \
	# do
	# 	json = CustomReportTemplate.to_jsonmodel(params[:id])

	# 	json_response(resolve_references(json, params[:resolve]))
	# end


	# Endpoint.delete('/repositories/:repo_id/custom_report_templates/:id')
	# 	.description("Delete an Custom Report Template")
	# 	.params(["id", :id],
	# 			["repo_id", :repo_id])
	# 	.permissions(['create_job'])
	# 	.returns([200, :deleted]) \
	# do
	# 	handle_delete(CustomReportTemplate, params[:id])
	# end
end