class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/families')
    .description("Create a family agent")
    .params(["agent", JSONModel(:agent_family), "The record to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :created],
             [400, :error]) \
  do
    with_record_conflict_reporting(AgentFamily, params[:agent]) do
      handle_create(AgentFamily, params[:agent])
    end
  end


  Endpoint.get('/agents/families')
    .description("List all family agents")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:agent_family)]"]) \
  do
    handle_listing(AgentFamily, params)
  end


  Endpoint.post('/agents/families/:id')
    .description("Update a family agent")
    .params(["id", :id],
            ["agent", JSONModel(:agent_family), "The updated record", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    with_record_conflict_reporting(AgentFamily, params[:agent]) do
      handle_update(AgentFamily, params[:id], params[:agent])
    end
  end


  Endpoint.get('/agents/families/:id')
    .description("Get a family by ID")
    .params(["id", Integer, "ID of the family agent"],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:agent)"],
             [404, "Not found"]) \
  do
    opts = {:calculate_linked_repositories => current_user.can?(:index_system)}
    json_response(resolve_references(AgentFamily.to_jsonmodel(AgentFamily.get_or_die(params[:id]), opts),
                                     params[:resolve]))
  end

  Endpoint.delete('/agents/families/:id')
    .description("Delete an agent family")
    .params(["id", Integer, "ID of the family agent"])
    .permissions([:delete_agent_record])
    .returns([200, :deleted]) \
  do
    handle_delete(AgentFamily, params[:id])
  end

end
