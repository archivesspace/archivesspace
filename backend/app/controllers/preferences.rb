class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/preferences')
    .description("Create a Preferences record")
    .params(["preference", JSONModel(:preference), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, :created],
             [400, :error]) \
  do
    check_permissions(params)
    handle_create(Preference, params[:preference])
  end


  Endpoint.get('/repositories/:repo_id/preferences/defaults')
    .description("Get the default set of Preferences for a Repository and optionally a user")
    .params(["repo_id", :repo_id],
            ["username", String, "The username to retrieve defaults for", :optional => true])
    .permissions([])
    .returns([200, "(defaults)"]) \
  do
    json_response(Preference.parsed_defaults_for( :repo_id => params[:repo_id], :user_id => params[:username] ))
  end


  Endpoint.get('/repositories/:repo_id/preferences/:id')
    .description("Get a Preferences record")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:preference)"]) \
  do
    json = Preference.to_jsonmodel(params[:id])

    json_response(json)
  end


  Endpoint.get('/repositories/:repo_id/current_preferences')
    .description("Get the Preferences records for the current repository and user.")
    .params(["repo_id", :repo_id])
    .permissions([])
    .returns([200, "{(:preference)}"]) \
  do
    json = Preference.current_preferences(params[:repo_id])

    json_response(json)
  end


  Endpoint.get('/current_global_preferences')
    .description("Get the global Preferences records for the current user.")
    .params()
    .permissions([])
    .returns([200, "{(:preference)}"]) \
  do
    json = Preference.current_preferences(Repository.global_repo_id)

    json_response(json)
  end


  Endpoint.post('/repositories/:repo_id/preferences/:id')
    .description("Update a Preferences record")
    .params(["id", :id],
            ["preference", JSONModel(:preference), "The updated record", :body => true],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, :updated],
             [400, :error]) \
  do
    check_permissions(params)
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
    check_permissions(params)
    handle_delete(Preference, params[:id])
  end


  def check_permissions(params)
    if (params.has_key?(:preference))
      user_id = params[:preference]['user_id']
      repo_id = params[:preference]['repo_id']
    else
      user_id = Preference[params[:id]].user_id
      repo_id = params[:repo_id]
    end

    # trying to edit global prefs
    if user_id.nil? &&
        repo_id == Repository.global_repo_id &&
        !current_user.can?(:administer_system)
      raise AccessDeniedException.new
    end

    # trying to edit repo prefs
    if user_id.nil? &&
        !current_user.can?(:manage_repository)
      raise AccessDeniedException.new
    end

    # trying to edit user prefs
    if user_id && user_id != current_user.id
      raise AccessDeniedException.new
    end
  end

end
