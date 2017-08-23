class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/assessment_attribute_definitions')
    .description("Update this repository's assessment attribute definitions")
    .params(["repo_id", :repo_id],
            ["assessment_attribute_definitions",
             JSONModel(:assessment_attribute_definitions),
             "The assessment attribute definitions",
             :body => true])
    .permissions([:manage_assessment_attributes])
    .returns([200, :updated]) \
  do
    AssessmentAttributeDefinitions.apply_definitions(params.fetch(:repo_id),
                                                    params.fetch(:assessment_attribute_definitions))

    [200, {"Content-Type" => "application/json"}, ASUtils.to_json(:status => 'Updated')]
  end

  Endpoint.get('/repositories/:repo_id/assessment_attribute_definitions')
    .description("Get this repository's assessment attribute definitions")
    .params(["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:assessment_attribute_definitions)"]) \
  do
    json_response(AssessmentAttributeDefinitions.get(params.fetch(:repo_id)))
  end

end
