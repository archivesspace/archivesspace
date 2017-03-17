class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/software')
    .description("Create a software agent")
    .params(["agent", JSONModel(:agent_software), "The record to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :created],
             [400, :error]) \
  do
    with_record_conflict_reporting(AgentSoftware, params[:agent]) do
      handle_create(AgentSoftware, params[:agent])
    end
  end


  Endpoint.get('/agents/software')
    .description("List all software agents")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:agent_software)]"]) \
  do
    handle_listing(AgentSoftware, params)
  end


  Endpoint.post('/agents/software/:id')
    .description("Update a software agent")
    .params(["id", :id],
            ["agent", JSONModel(:agent_software), "The updated record", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    with_record_conflict_reporting(AgentSoftware, params[:agent]) do
      handle_update(AgentSoftware, params[:id], params[:agent])
    end
  end


  Endpoint.get('/agents/software/:id')
    .description("Get a software agent by ID")
    .params(["id", Integer, "ID of the software agent"],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:agent)"],
             [404, "Not found"]) \
  do
    opts = {:calculate_linked_repositories => current_user.can?(:index_system)}
    json_response(resolve_references(AgentSoftware.to_jsonmodel(AgentSoftware.get_or_die(params[:id]), opts),
                                     params[:resolve]))
  end

  Endpoint.delete('/agents/software/:id')
    .description("Delete a software agent")
    .params(["id", Integer, "ID of the software agent"])
    .permissions([:delete_agent_record])
    .returns([200, :deleted]) \
  do
    handle_delete(AgentSoftware, params[:id])
  end

end
