require 'spec_helper'

# ANW-2829: agents reach repository-scoped records through more than the
# :linked_agents relationship. Classification and ClassificationTerm point at an
# agent through their 'creator' property (classification_creator_rlshp /
# classification_term_creator_rlshp), but the cross-repository guard only
# queries :linked_agents, so those links are invisible to it.
#
# There is no silent data loss: a database foreign key on the creator tables
# refuses the delete. But the user is shown a raw SQLIntegrityConstraintViolation
# instead of the guard's translated explanation, gets no "Linked Outside This
# Repository" badge warning them beforehand, and an administrator holding
# delete_agent_record_linked_elsewhere is blocked outright rather than being
# offered the confirmation step.
describe 'cross-repository guard and classification creator links' do

  def create_with_creator_in_repo(repo, agent, factory = :json_classification)
    JSONModel.set_repository(repo.id)
    RequestContext.put(:repo_id, repo.id)

    create(factory, 'creator' => {'ref' => agent.uri})
  end

  def delete_agent(agent, current_repo_id)
    url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent[:id]}" +
              "?current_repo_id=#{current_repo_id}")

    JSONModel::HTTP.delete_request(url)
  end

  before(:each) do
    @repo_a = create(:repo)
    @repo_b = create(:repo)

    group = Group.create_from_json(build(:json_group), :repo_id => @repo_a.id)
    group.grant("manage_agent_record")

    @user = make_test_user("agent_manager_for_classification_test")
    group.add_user(@user)

    @agent = AgentPerson.create_from_json(build(:json_agent_person))
  end

  describe 'the linked_in_other_repository flag' do
    it 'counts a Classification creator link in another repository' do
      create_with_creator_in_repo(@repo_b, @agent)

      expect(AgentPerson[@agent[:id]].linked_in_other_repository?(@repo_a.id)).to be true
    end

    it 'counts a ClassificationTerm creator link in another repository' do
      create_with_creator_in_repo(@repo_b, @agent, :json_classification_term)

      expect(AgentPerson[@agent[:id]].linked_in_other_repository?(@repo_a.id)).to be true
    end

    it 'is reported on the JSONModel, so the badge can warn before the user tries' do
      create_with_creator_in_repo(@repo_b, @agent)

      json = AgentPerson.to_jsonmodel(AgentPerson[@agent[:id]],
                                      :calculate_linked_in_other_repository => true,
                                      :current_repo_id => @repo_a.id)

      expect(json.linked_in_other_repository).to eq(true)
    end

    # Guards against over-correcting into "any creator link counts". Passes
    # today only because the link is invisible, so it is a regression guard
    # for the fix rather than evidence of current correctness.
    it "doesn't count a creator link within the caller's own repository" do
      create_with_creator_in_repo(@repo_a, @agent)

      expect(AgentPerson[@agent[:id]].linked_in_other_repository?(@repo_a.id)).to be false
    end
  end

  describe 'deleting the agent' do
    it 'explains the conflict instead of leaking a database constraint error' do
      create_with_creator_in_repo(@repo_b, @agent)

      response = as_test_user(@user.username) do
        delete_agent(@agent, @repo_a.id)
      end

      expect(response.code).to eq('409')
      expect(ASUtils.json_parse(response.body)['error']).to eq('linked_to_other_repo')
      expect(AgentPerson[@agent[:id]]).not_to be_nil
    end

    it 'does not leak a database constraint error to an administrator either' do
      create_with_creator_in_repo(@repo_b, @agent)

      response = delete_agent(@agent, @repo_a.id)

      expect(response.body).not_to include('SQLIntegrityConstraintViolationException')
    end
  end
end
