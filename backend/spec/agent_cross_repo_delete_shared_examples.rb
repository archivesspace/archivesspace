RSpec.shared_examples 'agent cross-repository delete guard' do |agent_model, agent_factory|

  def link_agent_to_new_accession_in_repo(agent, repo)
    RequestContext.put(:repo_id, repo.id)
    create(:json_accession, 'linked_agents' => [{
                                                   'ref' => agent.uri,
                                                   'role' => 'source'
                                                 }])
  end


  context 'when user has the manage_agent_record permission but not delete_agent_record_linked_elsewhere' do
    before(:each) do
      @repo_a = create(:repo)

      group = Group.create_from_json(build(:json_group), :repo_id => @repo_a.id)
      group.grant("manage_agent_record")

      @user = make_test_user("agent_manager")
      group.add_user(@user)
    end


    it 'blocks deletion when the agent is linked to a record in another repository' do
      repo_b = create(:repo)

      agent = agent_model.create_from_json(build(agent_factory))

      link_agent_to_new_accession_in_repo(agent, repo_b)

      RequestContext.put(:current_repo_id, @repo_a.id)

      as_test_user(@user.username) do
        expect {
          agent_model[agent[:id]].delete
        }.to raise_error(ConflictException)
      end
    end


    it 'blocks deletion when the agent is linked to 2+ other repositories, even if current_repo_id matches one of them' do
      repo_b = create(:repo)
      repo_c = create(:repo)

      agent = agent_model.create_from_json(build(agent_factory))

      link_agent_to_new_accession_in_repo(agent, repo_b)
      link_agent_to_new_accession_in_repo(agent, repo_c)

      RequestContext.put(:current_repo_id, repo_b.id)

      as_test_user(@user.username) do
        expect {
          agent_model[agent[:id]].delete
        }.to raise_error(ConflictException)
      end
    end


    it "allows deletion when the agent is linked only within the viewer's own repository" do
      agent = agent_model.create_from_json(build(agent_factory))
      link_agent_to_new_accession_in_repo(agent, @repo_a)

      RequestContext.put(:current_repo_id, @repo_a.id)

      as_test_user(@user.username) do
        expect {
          agent_model[agent[:id]].delete
        }.not_to raise_error
      end
    end


    it 'allows deletion when the agent has no links in another repository' do
      agent = agent_model.create_from_json(build(agent_factory))

      RequestContext.put(:current_repo_id, @repo_a.id)

      as_test_user(@user.username) do
        expect {
          agent_model[agent[:id]].delete
        }.not_to raise_error
      end
    end
  end


  context 'when an admin user who implicitly holds delete_agent_record_linked_elsewhere' do
    it 'allows deletion, even when the agent is linked to a record in another repository' do
      repo_b = create(:repo)

      agent = agent_model.create_from_json(build(agent_factory))

      link_agent_to_new_accession_in_repo(agent, repo_b)

      expect {
        agent_model[agent[:id]].delete
      }.not_to raise_error
    end
  end

end
