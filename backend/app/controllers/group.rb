class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/groups')
    .description("Create a group within a repository")
    .params(["group", JSONModel(:group), "The group to create", :body => true],
            ["repo_id", :repo_id])
    .preconditions(proc { current_user.can?(:manage_repository) })
    .returns([200, :created],
             [400, :error],
             [409, :conflict]) \
  do
    handle_create(Group, :group)
  end


  Endpoint.post('/repositories/:repo_id/groups/:group_id')
    .description("Update a group")
    .params(["group_id", Integer, "The Group ID to update"],
            ["group", JSONModel(:group), "The Group data to update", :body => true],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) replace the membership list with the list provided",
             :default => true])
    .preconditions(proc { current_user.can?(:manage_repository) })
    .returns([200, :updated],
             [400, :error],
             [409, :conflict]) \
  do
    handle_update(Group, :group_id, :group,
                  :with_members => params[:with_members])
  end


  Endpoint.get('/repositories/:repo_id/groups/:group_id')
    .description("Get a group by ID")
    .params(["group_id", Integer, "The group ID"],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) return the list of members with the group",
             :default => true])
    .preconditions(proc { current_user.can?(:manage_repository) })
    .returns([200, "(:group)"],
             [404, '{"error":"Group not found"}']) \
  do
    json = Group.to_jsonmodel(params[:group_id], :group, params[:repo_id],
                              :with_members => params[:with_members])

    json_response(json)
  end


  Endpoint.get('/repositories/:repo_id/groups')
    .description("Get a list of groups for a repository")
    .params(["repo_id", :repo_id],
            ["group_code", String, "Get groups by group code",
             :optional => true])
    .preconditions(proc { current_user.can?(:manage_repository) })
    .returns([200, "[(:resource)]"]) \
  do
    handle_listing(Group, :group, params)
  end
end
