RSpec.shared_examples "agent contact permissions" do |agent_type, agent_factory, name_factory|
  describe 'create action' do
    describe 'with contacts' do
      context 'when user has the manage_agent_record permission on any repository' do
        context 'when user has the view_agent_contact_record permission on any repository' do
          before :each do
            archivist = make_test_user("archivist")
            Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)
          end

          it "adds the contact" do
            as_test_user("archivist") do
              first_contact_params = build(:json_agent_contact).to_hash
              second_contact_params = build(:json_agent_contact).to_hash
              id = create(agent_factory, :agent_contacts => [first_contact_params, second_contact_params]).id

              agent_contacts = JSONModel(agent_type).find(id).agent_contacts

              expect(agent_contacts[0].to_hash).to deep_include(first_contact_params)
              expect(agent_contacts[1].to_hash).to deep_include(second_contact_params)
            end
          end
        end

        context 'when user does not have the view_agent_contact_record permission on any repository' do
          before :each do
            user = make_test_user("intern")
            Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
          end

          it "responds with access denied" do
            as_test_user("intern") do
              first_contact_params = build(:json_agent_contact).to_hash
              second_contact_params = build(:json_agent_contact).to_hash
              expect do
                create(agent_factory, :agent_contacts => [first_contact_params, second_contact_params]).id
              end.to raise_error(AccessDeniedException)
            end
          end
        end
      end

      context 'when user does not have the manage_agent_record permission on any repository' do
        context 'when user has the view_agent_contact_record permission on at least one repository' do
          before :each do
            group_data = {
              :group_code => "view-agent-contact-without-manage-agents",
              :description => "Can view agent agent contacts but cannot manage agents",
              :grants_permissions => ["view_repository", "update_accession_record", "update_resource_record",
                                      "update_digital_object_record", "create_job", "view_agent_contact_record", "view_agent_contact_record_global"]
            }

            Group.create_from_json(JSONModel(:group).from_hash(group_data),
                                   :repo_id => $repo_id)

            user = make_test_user("limited-user")
            Group[:group_code => 'view-agent-contact-without-manage-agents', :repo_id => $repo_id].add_user(user)
          end

          it "responds with access denied" do
            as_test_user("limited-user") do
              first_contact_params = build(:json_agent_contact).to_hash
              second_contact_params = build(:json_agent_contact).to_hash
              expect do
                create(agent_factory, :agent_contacts => [first_contact_params, second_contact_params]).id
              end.to raise_error(AccessDeniedException)
            end
          end
        end

        context 'when user does not have the view_agent_contact_record permission on any repository' do
          before :each do
            user = make_test_user("intern")
            Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
          end

          it "responds with access denied" do
            as_test_user("intern") do
              first_contact_params = build(:json_agent_contact).to_hash
              second_contact_params = build(:json_agent_contact).to_hash
              expect do
                create(agent_factory, :agent_contacts => [first_contact_params, second_contact_params]).id
              end.to raise_error(AccessDeniedException)
            end
          end
        end
      end
    end
  end

  describe 'update action' do
    describe 'adding contacts' do
      context 'when agent has no contacts' do
        let(:test_agent) do
          as_test_user("admin") do
            create(agent_factory, :agent_contacts => nil)
          end
        end

        context 'when user has the manage_agent_record permission on any repository' do
          context 'when user has the view_agent_contact_record permission on any repository' do
            before :each do
              archivist = make_test_user("archivist")
              Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)
            end

            it "persists the added contacts" do
              as_test_user("archivist") do
                agent = JSONModel(agent_type).find(test_agent.id)
                first_contact_params = build(:json_agent_contact).to_hash
                second_contact_params = build(:json_agent_contact).to_hash
                agent.agent_contacts = [first_contact_params, second_contact_params]
                agent.save

                agent = JSONModel(agent_type).find(agent.id)
                expect(agent.agent_contacts).to deep_include([first_contact_params, second_contact_params])
              end
            end
          end

          context 'when user does not have the view_agent_contact_record permission on any repository' do
            before :each do
              user = make_test_user("intern")
              Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
            end

            it "ignores the added contacts" do
              as_test_user("intern") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.agent_contacts = [build(:json_agent_contact).to_hash, build(:json_agent_contact).to_hash]
                expect { agent.save }.not_to raise_error
              end

              as_test_user('admin') do
                expect(JSONModel(agent_type).find(test_agent.id).agent_contacts.count).to eq(0)
              end
            end
          end
        end

        context 'when user does not have the manage_agent_record permission on any repository' do
          context 'when user has the view_agent_contact_record permission on at least one repository' do
            before :each do
              group_data = {
                :group_code => "view-agent-contact-without-manage-agents",
                :description => "Can view agent agent contacts but cannot manage agents",
                :grants_permissions => ["view_repository", "update_accession_record", "update_resource_record",
                                        "update_digital_object_record", "create_job", "view_agent_contact_record", "view_agent_contact_record_global"]
              }

              Group.create_from_json(JSONModel(:group).from_hash(group_data),
                                     :repo_id => $repo_id)

              user = make_test_user("limited-user")
              Group[:group_code => 'view-agent-contact-without-manage-agents', :repo_id => $repo_id].add_user(user)
            end

            it "responds with access denied and does not update agent contacts" do
              as_test_user("limited-user") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.agent_contacts = [build(:json_agent_contact), build(:json_agent_contact)]

                expect { agent.save }.to raise_error(AccessDeniedException)
              end

              as_test_user('admin') do
                expect(JSONModel(agent_type).find(test_agent.id).agent_contacts.count).to eq(0)
              end
            end
          end

          context 'when user does not have the view_agent_contact_record permission on any repository' do
            before :each do
              group_data = {
                :group_code => "without-view-agent-contact-or-manage-agents",
                :description => "Cannot view agent contacts or manage agents",
                :grants_permissions => ["view_repository", "update_accession_record", "update_resource_record",
                                        "update_digital_object_record", "create_job", "view_agent_contact_record_global"]
              }

              Group.create_from_json(JSONModel(:group).from_hash(group_data),
                                     :repo_id => $repo_id)

              user = make_test_user("very-limited-user")
              Group[:group_code => 'without-view-agent-contact-or-manage-agents', :repo_id => $repo_id].add_user(user)
            end

            it "responds with access denied" do
              as_test_user("very-limited-user") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.agent_contacts = [build(:json_agent_contact), build(:json_agent_contact)]
                agent.names << build(name_factory)

                expect { agent.save }.to raise_error(AccessDeniedException)
              end

              as_test_user('admin') do
                expect(JSONModel(agent_type).find(test_agent.id).agent_contacts.count).to eq(0)
              end
            end
          end
        end
      end
    end

    describe 'removing all contacts' do
      context 'when agent has contacts' do
        let(:first_contact_params) { build(:json_agent_contact).to_hash }
        let(:second_contact_params) { build(:json_agent_contact).to_hash }
        let(:test_agent) do
          as_test_user("admin") do
            create(agent_factory, agent_contacts: [first_contact_params, second_contact_params])
          end
        end

        context 'when user has the manage_agent_record permission on any repository' do
          context 'when user has the view_agent_contact_record permission on any repository' do
            before :each do
              archivist = make_test_user("archivist")
              Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)
            end

            it "removes all contacts" do
              as_test_user("archivist") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.agent_contacts = []
                agent.names << build(name_factory)
                expect { agent.save }.not_to raise_error

                persisted_agent = JSONModel(agent_type).find(test_agent.id)
                expect(persisted_agent.names.count).to eq(2)
                expect(persisted_agent.agent_contacts).to be_empty
              end

              as_test_user('admin') do
                expect(JSONModel(agent_type).find(test_agent.id).agent_contacts.count).to eq(0)
              end
            end
          end

          context 'when user does not have the view_agent_contact_record permission on any repository' do
            before :each do
              user = make_test_user("intern")
              Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
            end

            it "does not raise an error and does not remove the contacts" do
              as_test_user("intern") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.agent_contacts = []
                agent.names << build(name_factory)
                expect { agent.save }.not_to raise_error
              end

              as_test_user('admin') do
                persisted_agent = JSONModel(agent_type).find(test_agent.id)
                expect(persisted_agent.names.count).to eq(2)
                expect(persisted_agent.agent_contacts).to deep_include([first_contact_params, second_contact_params])
              end
            end
          end
        end
      end
    end

    describe 'without contact params' do
      context 'when agent has contacts' do
        let(:first_contact_params) { build(:json_agent_contact).to_hash }
        let(:second_contact_params) { build(:json_agent_contact).to_hash }
        let(:test_agent) do
          as_test_user("admin") do
            create(agent_factory, agent_contacts: [first_contact_params, second_contact_params])
          end
        end

        context 'when user has the manage_agent_record permission on any repository' do
          context 'when user has the view_agent_contact_record permission on any repository' do
            before :each do
              archivist = make_test_user("archivist")
              Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)
            end

            it "updates the names and removes the contacts" do
              as_test_user("archivist") do
                agent = JSONModel(agent_type).find(test_agent.id)
                agent.names << build(name_factory)
                agent.agent_contacts = nil
                agent.save

                agent = JSONModel(agent_type).find(agent.id)
                expect(agent.agent_contacts.count).to eq(0)
                expect(agent.names.count).to eq(2)
              end

              as_test_user('admin') do
                expect(JSONModel(agent_type).find(test_agent.id).agent_contacts.count).to eq(0)
              end
            end
          end

          context 'when user does not have the view_agent_contact_record permission on any repository' do
            before :each do
              user = make_test_user("intern")
              Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
            end

            it "updates the names but not the contacts" do
              as_test_user("intern") do
                agent = JSONModel(agent_type).find(test_agent.id)
                expect(agent.agent_contacts).to be_empty
                agent.names << build(name_factory)
                agent.agent_contacts = nil
                agent.save
              end

              as_test_user('admin') do
                agent = JSONModel(agent_type).find(test_agent.id)
                expect(agent.agent_contacts.count).to eq(2)
                expect(JSONModel(agent_type).find(agent.id).agent_contacts).to deep_include([first_contact_params, second_contact_params])

                expect(agent.names.count).to eq(2)
              end
            end
          end
        end
      end
    end
  end

  describe 'index action' do
    describe 'listing contact details' do
      context 'when user has the manage_agent_record permission on any repository' do
        let!(:agents_with_contacts) do
          as_test_user("admin") do
            create_list(agent_factory, 2, agent_contacts: [build(:json_agent_contact), build(:json_agent_contact)])
          end
        end

        context 'when user has the view_agent_contact_record permission on any repository' do
          before :each do
            as_test_user("admin") do
              archivist = make_test_user("archivist")
              Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)
            end
          end

          it "resolves contact details" do
            as_test_user("archivist") do
              agents = JSONModel(agent_type).all(id_set: agents_with_contacts.map(&:id))
              agents.each do |agent|
                expect(agent.to_hash['agent_contacts']).not_to be_empty
              end
            end
          end
        end

        context 'when user does not have the view_agent_contact_record permission on any repository' do
          before :each do
            user = make_test_user("intern")
            Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
          end

          it "does not list agent contacts" do
            as_test_user("intern") do
              agents = JSONModel(agent_type).all(id_set: agents_with_contacts.map(&:id))
              agents.each do |agent|
                expect(agent.to_hash['agent_contacts']).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
