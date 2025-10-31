class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/people')
    .description("Create a person agent")
    .params(["agent", JSONModel(:agent_person), "The record to create", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :created],
             [400, :error]) \
  do
    if !current_user.can?(:view_agent_contact_record_global) && params[:agent]['agent_contacts'] && !params[:agent]['agent_contacts'].empty?
      raise AccessDeniedException.new(:target_agent => ["Creating agent with contacts permission denied"])
    end

    with_record_conflict_reporting(AgentPerson, params[:agent]) do
      handle_create(AgentPerson, params[:agent])
    end
  end


  Endpoint.get('/agents/people')
    .description("List all person agents")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:agent_person)]"]) \
  do
    handle_listing(AgentPerson, params)
  end


  Endpoint.post('/agents/people/:id')
    .description("Update a person agent")
    .params(["id", :id],
            ["agent", JSONModel(:agent_person), "The updated record", :body => true])
    .permissions([:update_agent_record])
    .returns([200, :updated],
             [400, :error]) \
  do
    opts = {
      skip_agent_contacts: !current_user.can?(:view_agent_contact_record_global)
    }

    with_record_conflict_reporting(AgentPerson, params[:agent]) do
      handle_update(AgentPerson, params[:id], params[:agent], opts)
    end
  end


  Endpoint.get('/agents/people/:id')
    .description("Get a person by ID")
    .params(["id", Integer, "ID of the person agent"],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:agent_person)"],
             [404, "Not found"]) \
  do
    opts = {
      calculate_linked_repositories: current_user.can?(:index_system),
      hide_agent_contacts: !current_user.can?(:view_agent_contact_record_global)
    }
    json_response(resolve_references(AgentPerson.to_jsonmodel(AgentPerson.get_or_die(params[:id]), opts),
                                     params[:resolve]))
  end


  Endpoint.delete('/agents/people/:id')
    .description("Delete an agent person")
    .params(["id", Integer, "ID of the person agent"])
    .permissions([:delete_agent_record])
    .returns([200, :deleted]) \
  do
    handle_delete(AgentPerson, params[:id])
  end


  Endpoint.post('/agents/people/:id/publish')
    .description("Publish an agent person and all its sub-records")
    .example("shell") do
      <<~SHELL
        curl -H "X-ArchivesSpace-Session: $SESSION" \
        "http://localhost:8089/agents/people/1/publish"
      SHELL
    end
    .params(["id", :id])
    .permissions([:update_agent_record])
    .no_data(true)
    .returns([200, :updated],
             [400, :error]) \
  do
    agent = AgentPerson.get_or_die(params[:id])
    agent.publish!

    updated_response(agent)
  end


end
