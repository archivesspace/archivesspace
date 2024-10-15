require 'spec_helper'
require 'rails_helper'

describe AgentsController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository
    allow(RequiredFields).to receive(:get)
                               .with("agent_person")
                               .and_return(RequiredFields.from_hash(record_type: "agent_person"))

  end

  describe "create" do

    it "can create an agent" do
      agent = build(:json_agent_person)
      post :create, params: {
             agent_type: "agent_person",
             agent: agent.to_hash
           }

      expect(response.status).to eq(302)
      response.body.match('/agent_person\/(\d+)\/edit')
      expect(agent.names[0]['primary_name']).to eq(JSONModel(:agent_person).find($1).names[0]['primary_name'])
    end

  end

  describe "user-managed required fields" do
    let(:json_required_fields) {
      JSONModel(:required_fields).from_hash(
        {
          record_type: 'agent_person',
          subrecord_requirements: [
            {
              property: "metadata_rights_declarations",
              record_type: "metadata_rights_declaration",
              required: true
            },
            {
              property: "agent_maintenance_histories",
              record_type: "agent_maintenance_history",
              required_fields: ["descriptive_note"]
            }
          ]
        })
    }

    it "adds missing user-managed required subrecords and subrecord fields to object errors" do
      agent = build(:json_agent_person,
                    :agent_maintenance_histories => [
                      build(:json_agent_maintenance_history,
                            :descriptive_note => nil
                           )])

      allow(RequiredFields).to receive(:get)
                                 .with("agent_person")
                                 .and_return(RequiredFields.new(json_required_fields))

      post :create, params: {
             agent_type: "agent_person",
             agent: agent.to_hash
           }

      obj = assigns(:agent)
      expect(obj._exceptions[:errors]).to eq({
                                               "metadata_rights_declarations"=>["Subrecord is required but was missing"],
                                               "agent_maintenance_histories/0/descriptive_note" => ["Property is required but was missing"]
                                             })

    end

    it "can build a form for viewing and editing user-managed required fields and subrecords" do
      allow(RequiredFields).to receive(:get)
                                 .with("agent_person")
                                 .and_return(RequiredFields.new(json_required_fields))

      get :required, params: {
             agent_type: "agent_person",
          }

      expect(assigns(:required_fields).required?("metadata_rights_declarations", "metadata_rights_declaration")).to be true
      assert_select("input[name='agent[metadata_rights_declarations][0][jsonmodel_type]'][value='metadata_rights_declaration']")
      assert_select("input[name='agent[metadata_rights_declarations][0][required]'][value='true'][checked='checked']")
      # required subform fields are flagged on the schema property with a string that is the subrecord type
      assert_select("input[name='agent[agent_maintenance_histories][0][descriptive_note]'][value='agent_maintenance_history'][checked='checked']")
    end
  end

  describe "merge agent preview" do
    it "redirects to agent record if merge_candidate is related" do
      merge_candidate = create(:json_agent_person)
      agent = create(:json_agent_person,
                     related_agents: [
                       JSONModel(:agent_relationship_parentchild).new({ :ref => merge_candidate.uri, :relator => 'is_child_of' }).to_hash
                     ])

      post :merge_selector, params: {
             agent_type: "agent_person",
             id: agent.id,
             refs: merge_candidate.uri
           }

      expect(response).to redirect_to("/agents/agent_person/#{agent.id}")
      expect(request.flash[:error]).to eq("These agents have a relationship. Remove relationship before proceeding with merge.")
    end
  end

  describe "merging agents" do
    it "preserves linked agent roles on affected resource or archival object when an agent is merged" do
      destination_agent = create(:json_agent_person)
      source_agent = create(:json_agent_person)

      affected_resource = create(:resource, title: 'resource')
      affected_resource.linked_agents.append({'ref' => destination_agent.uri, 'role' => 'creator'})
      affected_resource.linked_agents.append({'ref' => source_agent.uri, 'role' => 'source'})
      affected_resource.save

      affected_ao = create(:archival_object, resource: {'ref' => create(:resource).uri}, title: 'ao')
      affected_ao.linked_agents.append({'ref' => destination_agent.uri, 'role' => 'creator'})
      affected_ao.linked_agents.append({'ref' => source_agent.uri, 'role' => 'source'})
      affected_ao.save

      run_index_round

      post :merge_detail, params: {
        agent_type: 'agent_person',
        id: destination_agent.id,
        merge_candidate_uri: source_agent.uri,
        agent: {'does not' => 'matter'}
      }

      # the affected records should now still have both roles but linked only to the merge destination agent
      affected_resource.refetch
      expect(affected_resource.linked_agents.pluck('role')).to contain_exactly('creator', 'source')
      expect(affected_resource.linked_agents.pluck('ref').uniq).to contain_exactly(destination_agent.uri)

      affected_ao.refetch
      expect(affected_ao.linked_agents.pluck('role')).to contain_exactly('creator', 'source')
      expect(affected_ao.linked_agents.pluck('ref').uniq).to contain_exactly(destination_agent.uri)
    end
  end
end
