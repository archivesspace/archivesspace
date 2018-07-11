class ArchivesSpaceService < Sinatra::Base


  # Repositories with their agent representations
  Endpoint.get('/repositories/with_agent/:id')
    .description("Get a Repository by ID, including its agent representation")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:repository_with_agent)"],
             [404, "Not found"]) \
  do
    repo = Repository.to_jsonmodel(params[:id])
    agent = nil

    if repo.agent_representation
      agent_id = JSONModel(:agent_corporate_entity).id_for(repo.agent_representation['ref'])
      agent = AgentCorporateEntity.to_jsonmodel(agent_id)
    end

    json_response(JSONModel(:repository_with_agent).
                  from_hash(:repository => repo,
                            :agent_representation => agent,
                            :uri => JSONModel(:repository_with_agent).uri_for(params[:id])))
  end


  Endpoint.post('/repositories/with_agent')
    .description("Create a Repository with an agent representation")
    .params(["repository_with_agent",
             JSONModel(:repository_with_agent),
             "The record to create",
             :body => true])
    .permissions([:create_repository])
    .returns([200, :created],
             [400, :error],
             [403, :access_denied]) \
  do
    rwa = params[:repository_with_agent]
    agent_id = nil

    if rwa.agent_representation
      agent_id = AgentCorporateEntity.create_from_json(JSONModel(:agent_corporate_entity).
                                                       from_hash(rwa.agent_representation)).id
    end

    repo = Repository.create_from_json(JSONModel(:repository).from_hash(rwa.repository),
                                       :agent_representation_id => agent_id)

    created_response(repo, rwa)
  end


  Endpoint.post('/repositories/with_agent/:id')
    .description("Update a repository with an agent representation")
    .params(["id", :id],
            ["repository_with_agent",
             JSONModel(:repository_with_agent),
             "The updated record",
             :body => true])
    .permissions([:create_repository])
    .returns([200, :updated]) \
  do
    rwa = params[:repository_with_agent]

    repo = Repository.get_or_die(params[:id])
    agent_representation_id = repo.agent_representation_id

    if rwa.agent_representation
      if agent_representation_id
        # Update the existing agent
        agent = AgentCorporateEntity.get_or_die(agent_representation_id)
        agent.update_from_json(JSONModel(:agent_corporate_entity).
                               from_hash(rwa.agent_representation))
      else
        # Create a new agent
        agent = AgentCorporateEntity.create_from_json(JSONModel(:agent_corporate_entity).
                                              from_hash(rwa.agent_representation))
        agent_representation_id = agent.id
      end
    else
      # Unlink the agent (if there is one)
      agent_representation_id = nil
    end

    repo.update_from_json(JSONModel(:repository).from_hash(rwa.repository),
                          :agent_representation_id => agent_representation_id)

    updated_response(repo, rwa)
  end


  # Regular (unadorned) repositories
  Endpoint.post('/repositories/:id')
  .description("Update a repository")
  .params(["id", :id],
          ["repository", JSONModel(:repository), "The updated record", :body => true])
  .permissions([:create_repository])
  .returns([200, :updated]) \
  do
    handle_update(Repository, params[:id], params[:repository])
  end


  Endpoint.post('/repositories')
    .description("Create a Repository")
    .params(["repository", JSONModel(:repository), "The record to create", :body => true])
    .permissions([:create_repository])
    .returns([200, :created],
             [400, :error],
             [403, :access_denied]) \
  do

    
      # we need to check if the Agent for the repo has already been created 
      nce =  NameCorporateEntity.find(Sequel.like(:primary_name,params[:repository]['repo_code']))
    
      unless nce.nil?
        agent_id = nce.agent_corporate_entity_id
      else 
        # Create a dummy agent for this repository, since none was specified.
        name = {
          'primary_name' => params[:repository]['repo_code'],
          'sort_name' => params[:repository]['repo_code'],
          'source' => 'local'
        }

        contact = {
          'name' => params[:repository]['repo_code']
        }

        json = JSONModel(:agent_corporate_entity).from_hash('names' => [name],
                                                          'agent_contacts' => [contact])
        agent = AgentCorporateEntity.create_from_json(json)
        agent_id = agent.id 
   
      end
      
    
    handle_create(Repository, params[:repository], :agent_representation_id => agent_id)
  end


  Endpoint.get('/repositories/:id')
    .description("Get a Repository by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:repository)"],
             [404, "Not found"]) \
  do
    json_response(resolve_references(Repository.to_jsonmodel(Repository.get_or_die(params[:id])),
                                     params[:resolve]))
  end


  Endpoint.get('/repositories')
    .description("Get a list of Repositories")
    .params(["resolve", :resolve])
    .permissions([])
    .returns([200, "[(:repository)]"]) \
  do
    handle_unlimited_listing(Repository, :hidden => 0)
  end


  Endpoint.delete('/repositories/:repo_id')
    .description("Delete a Repository")
    .params(["repo_id", :repo_id])
    .permissions([:delete_repository])
    .returns([200, :deleted]) \
  do
    begin
      handle_delete(Repository, params[:repo_id])
    rescue Sequel::DatabaseError => e
      raise RepositoryNotEmpty.new
    end
  end


end
