class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/preferences')
    .description("Create a Preferences record")
    .params(["preference", JSONModel(:preference), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :created],
             [400, :error]) \
  do
    handle_create(Preference, params[:preference])
  end


  Endpoint.get('/repositories/:repo_id/preferences/defaults')
    .description("Get the default set of Preferences for a Repository and optionally a user")
    .params(["repo_id", :repo_id],
            ["username", String, "The username to retrieve defaults for", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(defaults)"]) \
  do
    json_response(Preference.defaults_for(params[:repo_id], params[:username]))
  end


  Endpoint.get('/repositories/:repo_id/preferences/:id')
    .description("Get a Preferences record")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:preference)"]) \
  do
    json = Preference.to_jsonmodel(params[:id])

    json_response(json)
  end


  Endpoint.post('/repositories/:repo_id/preferences/:id')
    .description("Update a Preferences record")
    .params(["id", :id],
            ["preference", JSONModel(:preference), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_archival_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    handle_update(Preference, params[:id], params[:preference])
  end


  Endpoint.get('/repositories/:repo_id/preferences')
    .description("Get a list of Preferences for a Repository and optionally a user")
    .params(["repo_id", :repo_id],
            ["user_id", Integer, "The username to retrieve defaults for", :optional => true])
    .permissions([:view_repository])
    .returns([200, "[(:preference)]"]) \
  do
    handle_unlimited_listing(Preference, params)
  end


  Endpoint.delete('/repositories/:repo_id/preferences/:id')
    .description("Delete a Preferences record")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:delete_archival_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Preference, params[:id])
  end

end
