class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/groups')
    .description("Create a group within a repository")
    .params(["group", JSONModel(:group), "The record to create", :body => true],
            ["repo_id", :repo_id])
    .permissions([:manage_repository])
    .returns([200, :created],
             [400, :error],
             [409, :conflict]) \
  do
    handle_create(Group, params[:group])
  end


  Endpoint.post('/repositories/:repo_id/groups/:id')
    .description("Update a group")
    .params(["id", :id],
            ["group", JSONModel(:group), "The updated record", :body => true],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) replace the membership list with the list provided",
             :default => true])
    .permissions([:manage_repository])
    .returns([200, :updated],
             [400, :error],
             [409, :conflict]) \
  do
    handle_update(Group, params[:id], params[:group],
                  :with_members => params[:with_members])
  end


  Endpoint.get('/repositories/:repo_id/groups/:id')
    .description("Get a group by ID")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["with_members",
             BooleanParam,
             "If 'true' (the default) return the list of members with the group",
             :default => true])
    .permissions([:manage_repository])
    .returns([200, "(:group)"],
             [404, "Not found"]) \
  do
    json = Group.to_jsonmodel(params[:id],
                              :with_members => params[:with_members])

    json_response(json)
  end


  Endpoint.delete('/repositories/:repo_id/groups/:id')
    .description("Delete a group by ID")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:manage_repository])
    .returns([200, "(:group)"],
             [404, "Not found"]) \
  do
    handle_delete(Group, params[:id])
  end


  Endpoint.get('/repositories/:repo_id/groups')
    .description("Get a list of groups for a repository")
    .params(["repo_id", :repo_id],
            ["group_code", String, "Get groups by group code",
             :optional => true])
    .permissions([:manage_repository])
    .returns([200, "[(:resource)]"]) \
  do
    handle_unlimited_listing(Group, params.has_key?(:group_code) ? {:group_code => params[:group_code]} : {})
  end
end
