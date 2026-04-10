class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/repositories/:repo_id/required_fields/:record_type')
    .description("Add or change repository-level required fields for an agent record type")
    .example("shell") do
      <<~CONTENTS
        # Add required field to agent_person in repository 2
        curl -H 'Content-Type: text/json' -H "X-ArchivesSpace-Session: $SESSION" \
          "http://localhost:8089/repositories/2/required_fields/agent_person" \
          -d '{
               "jsonmodel_type": "required_fields",
               "record_type": "agent_person",
               "subrecord_requirements": [
                 {
                   "property": "metadata_rights_declarations",
                   "record_type": "metadata_rights_declaration",
                   "required": true,
                   "required_fields": [
                     "descriptive_note"
                   ]
                 }
               ]
             }'

        # Remove required fields from agent_person in repository 2
        curl -H 'Content-Type: text/json' -H "X-ArchivesSpace-Session: $SESSION" \
          "http://localhost:8089/repositories/2/required_fields/agent_person" \
          -d '{
               "jsonmodel_type": "required_fields",
               "record_type": "agent_person",
               "subrecord_requirements": []
             }'
       CONTENTS
    end
    .params(["required_fields", JSONModel(:required_fields), "The fields required", :body => true],
            ["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:manage_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    obj = RequiredFields.create_or_update(params[:required_fields], params[:repo_id], params[:record_type])

    updated_response(obj)
  end


  Endpoint.get('/repositories/:repo_id/required_fields/:record_type')
    .description("Get custom, repository-level required fields for an agent record type")
    .params(["repo_id", :repo_id],
            ["record_type", String])
    .permissions([:view_repository])
    .returns([200, :created],
             [400, :error]) \
  do
    id = "#{params[:repo_id]}_#{params[:record_type]}"
    json = RequiredFields.to_jsonmodel(id)

    json_response(json)
  end



end
