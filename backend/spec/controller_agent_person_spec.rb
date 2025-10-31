require 'spec_helper'
require 'agent_spec_helper'

describe 'Person agent controller' do
  describe 'update action' do
    describe 'adding contacts' do
      context 'when person has no contacts' do
        let(:agent_person) do
          as_test_user("admin") do
            create(:json_agent_person, :agent_contacts => nil)
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
                person = JSONModel(:agent_person).find(agent_person.id)
                first_contact_params = build(:json_agent_contact).to_hash
                second_contact_params = build(:json_agent_contact).to_hash
                person.agent_contacts = [first_contact_params, second_contact_params]
                person.save

                person = JSONModel(:agent_person).find(person.id)
                expect(person.agent_contacts).to deep_include([first_contact_params, second_contact_params])
              end
            end

            context 'when user does not have the view_agent_contact_record permission on any repository' do
              before :each do
                user = make_test_user("intern")
                Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
              end

              it "ignores the added contacts" do
                as_test_user("intern") do
                  person = JSONModel(:agent_person).find(agent_person.id)
                  person.agent_contacts = [build(:json_agent_contact).to_hash, build(:json_agent_contact).to_hash]
                  expect { person.save }.not_to raise_error
                end

                as_test_user('admin') do
                  expect(JSONModel(:agent_person).find(agent_person.id).agent_contacts.count).to eq(0)
                end
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
                person = JSONModel(:agent_person).find(agent_person.id)
                person.agent_contacts = [build(:json_agent_contact), build(:json_agent_contact)]

                expect { person.save }.to raise_error(AccessDeniedException)
              end

              as_test_user('admin') do
                expect(JSONModel(:agent_person).find(agent_person.id).agent_contacts.count).to eq(0)
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
                person = JSONModel(:agent_person).find(agent_person.id)
                person.agent_contacts = [build(:json_agent_contact), build(:json_agent_contact)]
                person.names << build(:json_name_person)

                expect { person.save }.to raise_error(AccessDeniedException)
              end

              as_test_user('admin') do
                expect(JSONModel(:agent_person).find(agent_person.id).agent_contacts.count).to eq(0)
              end
            end
          end
        end
      end
    end

    describe 'removing all contacts' do
      context 'when person has contacts' do
        let(:first_contact_params) { build(:json_agent_contact).to_hash }
        let(:second_contact_params) { build(:json_agent_contact).to_hash }
        let(:agent_person) do
          as_test_user("admin") do
            person = create(:json_agent_person, agent_contacts: [first_contact_params, second_contact_params])
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
                person = JSONModel(:agent_person).find(agent_person.id)
                person.agent_contacts = []
                person.names << build(:json_name_person)
                expect { person.save }.not_to raise_error

                persisted_agent = JSONModel(:agent_person).find(agent_person.id)
                expect(persisted_agent.names.count).to eq(2)
                expect(persisted_agent.agent_contacts).to be_empty
              end

              as_test_user('admin') do
                expect(JSONModel(:agent_person).find(agent_person.id).agent_contacts.count).to eq(0)
              end
            end

            context 'when user does not have the view_agent_contact_record permission on any repository' do
              before :each do
                user = make_test_user("intern")
                Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
              end

              it "does not raise an error and does not remove the contacts" do
                as_test_user("intern") do
                  person = JSONModel(:agent_person).find(agent_person.id)
                  person.agent_contacts = []
                  person.names << build(:json_name_person)
                  expect { person.save }.not_to raise_error
                end

                as_test_user('archivist') do
                  persisted_agent = JSONModel(:agent_person).find(agent_person.id)
                  expect(persisted_agent.names.count).to eq(2)
                  expect(persisted_agent.agent_contacts).to deep_include([first_contact_params, second_contact_params])
                end
              end
            end
          end
        end
      end
    end

    describe 'without contact params' do
      context 'when person has contacts' do
        let(:first_contact_params) { build(:json_agent_contact).to_hash }
        let(:second_contact_params) { build(:json_agent_contact).to_hash }
        let(:agent_person) do
          as_test_user("admin") do
            create(:json_agent_person, agent_contacts: [first_contact_params, second_contact_params])
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
                person = JSONModel(:agent_person).find(agent_person.id)
                person.names << build(:json_name_person)
                person.agent_contacts = nil
                person.save

                person = JSONModel(:agent_person).find(person.id)
                expect(person.agent_contacts.count).to eq(0)
                expect(person.names.count).to eq(2)
              end

              as_test_user('admin') do
                expect(JSONModel(:agent_person).find(agent_person.id).agent_contacts.count).to eq(0)
              end
            end

            context 'when user does not have the view_agent_contact_record permission on any repository' do
              before :each do
                user = make_test_user("intern")
                Group[:group_code => 'repository-advanced-data-entry', :repo_id => $repo_id].add_user(user)
              end

              it "updates the names but not the contacts" do
                as_test_user("intern") do
                  person = JSONModel(:agent_person).find(agent_person.id)
                  expect(person.agent_contacts).to be_empty
                  person.names << build(:json_name_person)
                  person.agent_contacts = nil
                  person.save
                end

                as_test_user('admin') do
                  person = JSONModel(:agent_person).find(agent_person.id)
                  expect(person.agent_contacts.count).to eq(2)
                  expect(JSONModel(:agent_person).find(person.id).agent_contacts).to deep_include([first_contact_params, second_contact_params])

                  expect(person.names.count).to eq(2)
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'create action' do
    it "persists the created person" do
      opts = {:names => [build(:json_name_person)]}

      id = create(:json_agent_person, opts).id
      expect(JSONModel(:agent_person).find(id).names.first['primary_name']).to eq(opts[:names][0]['primary_name'])
    end

    it "persists dates of existence" do
      date = build(:json_structured_date_label, :date_label => "existence")
      id = create(:json_agent_person, {:dates_of_existence => [date]}).id
      agent = JSONModel(:agent_person).find(id)

      expect(agent.dates_of_existence.length).to eq(1)
      expect(agent.dates_of_existence[0]["structured_date_single"]["date_expression"]).to eq(date["structured_date_single"]["date_expression"])
    end

    it "persists use dates" do
      date = build(:json_structured_date_label, {:date_label => "usage"})
      name = build(:json_name_person, {:use_dates => [date]})
      id = create(:json_agent_person, {:names => [name]}).id

      agent = JSONModel(:agent_person).find(id)
      expect(agent.names[0]['use_dates'].length).to eq(1)
    end

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
              id = create(:json_agent_person, :agent_contacts => [first_contact_params, second_contact_params]).id

              person_contacts = JSONModel(:agent_person).find(id).agent_contacts

              expect(person_contacts[0].to_hash).to deep_include(first_contact_params)
              expect(person_contacts[1].to_hash).to deep_include(second_contact_params)
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
                  create(:json_agent_person, :agent_contacts => [first_contact_params, second_contact_params]).id
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
                  create(:json_agent_person, :agent_contacts => [first_contact_params, second_contact_params]).id
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
                  create(:json_agent_person, :agent_contacts => [first_contact_params, second_contact_params]).id
                end.to raise_error(AccessDeniedException)
              end
            end
          end
        end
      end
    end

    describe 'with notes' do
      it "allows people to have a bioghist notes" do
        n1 = build(:json_note_bioghist)
        id = create(:json_agent_person, {:notes => [n1]}).id
        agent = JSONModel(:agent_person).find(id)

        expect(agent.notes.length).to eq(1)
        expect(agent.notes[0]["label"]).to eq(n1.label)
      end

      it "allows people to have a general_context notes" do
        n1 = build(:json_note_general_context)
        id = create(:json_agent_person, {:notes => [n1]}).id
        agent = JSONModel(:agent_person).find(id)

        expect(agent.notes.length).to eq(1)
        expect(agent.notes[0]["label"]).to eq(n1.label)
      end

      it "throws an error if created with an invalid note type" do
        n1 = build(:json_note_bibliography)

        expect { create(:json_agent_person, {:notes => [n1.to_json]}) }.to raise_error(JSONModel::ValidationException)
      end
    end

    describe 'persisting a sort name' do
      context 'when a sort name is provided' do
        it "persists the provided sort name" do
          opts = {:names => [build(:json_name_person, :sort_name => "Custom Sort Name", :sort_name_auto_generate => false)]}

          id = create(:json_agent_person, opts).id
          expect(JSONModel(:agent_person).find(id).names.first['sort_name']).to eq(opts[:names][0]['sort_name'])
        end
      end

      context 'when a sort name is not provided' do
        it "auto-generates the sort name" do
          id = create(:json_agent_person, {:names => [build(:json_name_person, {:primary_name => "Hendrix", :rest_of_name => "Jimi", :title => "Mr", :name_order => "direct", :sort_name_auto_generate => true})]}).id
          agent = JSONModel(:agent_person).find(id)

          expect(agent.names.first['sort_name']).to match(/\AJimi Hendrix,.* Mr/)
          agent.names.first['name_order'] = "direct"
          agent.save

          agent = JSONModel(:agent_person).find(id)

          expect(agent.names.first['sort_name']).to match(/\AJimi Hendrix,.* Mr/)

          aggregate_failures "adding a readonly 'title' of the first name's sort_name" do
            expect(agent.title).to match(/Jimi Hendrix,.* Mr/)
          end
        end

        it "auto-generates the sort name for a parallel name" do
          id = create(:json_agent_person,
            {
              :names => [build(:json_name_person, {
                                 :primary_name => "Caesar",
                                 :rest_of_name => "Julius",
                                 :name_order => "direct",
                                 :sort_name_auto_generate => true,
                                 :parallel_names => [{:primary_name => 'Gaius Julius Caesar', :name_order => "direct"}]
                               })]
            }).id

          agent = JSONModel(:agent_person).find(id)

          expect(agent.names.first['sort_name']).to match(/^Julius Caesar/)
          expect(agent.names.first['parallel_names'].first['sort_name']).to match(/^Gaius Julius Caesar/)

          agent.names.first['parallel_names'].first['title'] = "Dictator"
          agent.save

          expect(JSONModel(:agent_person).find(id).names.first['parallel_names'].first['sort_name']).to match(/^Gaius.*Dictator$/)
        end
      end
    end
  end

  describe 'index action' do
    it "paginates the list of person agents" do
      count = JSONModel(:agent_person).all(:page => 1)['results'].count
      if count > 8
        raise "too many agents in the test db for pagination testing"
      end
      2.times { create(:json_agent_person) }
      expect(JSONModel(:agent_person).all(:page => 1)['results'].count).to eq(count + 2)
    end

    describe 'listing contact details' do
      context 'when user has the manage_agent_record permission on any repository' do
        let!(:agents_with_contacts) do
          as_test_user("admin") do
            create_list(:json_agent_person, 2, agent_contacts: [build(:json_agent_contact), build(:json_agent_contact)])
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
              agents = JSONModel(:agent_person).all(id_set: agents_with_contacts.map(&:id))
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
              agents = JSONModel(:agent_person).all(id_set: agents_with_contacts.map(&:id))
              agents.each do |agent|
                expect(agent.to_hash['agent_contacts']).to be_empty
              end
            end
          end
        end
      end
    end
  end

  describe 'publish action' do
    it "publishes the person agent and subrecords when /publish is POSTed" do
      person = create(:json_agent_person, {
                        :publish => false,
                        :names => [build(:json_name_person)],
                        :external_documents => [build(:json_external_document, {:publish => false})],
                        :agent_places => [build(:json_agent_place)]
                      })

      # Confirm various subrecords are unpublished
      person = JSONModel(:agent_person).find(person.id)
      expect(person.publish).to be_falsey
      expect(person.external_documents[0]['publish']).to be_falsey
      expect(person.agent_places[0]['publish']).to be_falsey
      expect(person.agent_places[0]['notes'][0]['publish']).to be_falsey

      url = URI("#{JSONModel::HTTP.backend_url}#{person.uri}/publish")

      request = Net::HTTP::Post.new(url.request_uri)
      response = JSONModel::HTTP.do_http_request(url, request)

      # Now they're published
      person = JSONModel(:agent_person).find(person.id)
      expect(person.publish).to be_truthy
      expect(person.external_documents[0]['publish']).to be_truthy
      expect(person.agent_places[0]['publish']).to be_truthy
      expect(person.agent_places[0]['notes'][0]['publish']).to be_truthy
    end
  end


  describe "subrecord CRUD" do
    before :each do
      add_gender_values
    end

    it "creates agent subrecords on POST if appropriate" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      expect(AgentRecordControl.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentAlternateSet.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentConventionsDeclaration.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentSources.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentOtherAgencyCodes.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentMaintenanceHistory.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentRecordIdentifier.where(:agent_person_id => agent_id).count).to eq(1)
      expect(StructuredDateLabel.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentPlace.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentOccupation.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentFunction.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentTopic.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentIdentifier.where(:agent_person_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(1)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(1)
      expect(AgentResource.where(:agent_person_id => agent_id).count).to eq(1)
    end

    it "deletes agent subrecords when parent agent is deleted" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent_id}")
      response = JSONModel::HTTP.delete_request(url)

      expect(AgentRecordControl.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentAlternateSet.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentConventionsDeclaration.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentSources.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentOtherAgencyCodes.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentMaintenanceHistory.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentRecordIdentifier.where(:agent_person_id => agent_id).count).to eq(0)
      expect(StructuredDateLabel.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentPlace.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentOccupation.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentFunction.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentTopic.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentIdentifier.where(:agent_person_id => agent_id).count).to eq(0)
      expect(UsedLanguage.where(:agent_person_id => agent_id).count).to eq(0)
      expect(AgentResource.where(:agent_person_id => agent_id).count).to eq(0)
    end

    it "gets subrecords along with agent" do
      agent_id = create_agent_via_api(:person, {:create_subrecords => true})
      expect(agent_id).to_not eq(-1)

      url = URI("#{JSONModel::HTTP.backend_url}/agents/people/#{agent_id}")
      response = JSONModel::HTTP.get_response(url)
      json_response = ASUtils.json_parse(response.body)

      expect(json_response["agent_record_controls"].length).to eq(1)
      expect(json_response["agent_alternate_sets"].length).to eq(1)
      expect(json_response["agent_conventions_declarations"].length).to eq(1)
      expect(json_response["agent_other_agency_codes"].length).to eq(1)
      expect(json_response["agent_maintenance_histories"].length).to eq(1)
      expect(json_response["agent_record_identifiers"].length).to eq(1)
      expect(json_response["agent_sources"].length).to eq(1)
      expect(json_response["dates_of_existence"].length).to eq(1)
      expect(json_response["agent_places"].length).to eq(1)
      expect(json_response["agent_occupations"].length).to eq(1)
      expect(json_response["agent_functions"].length).to eq(1)
      expect(json_response["agent_topics"].length).to eq(1)
      expect(json_response["agent_identifiers"].length).to eq(1)
      expect(json_response["used_languages"].length).to eq(1)
      expect(json_response["agent_resources"].length).to eq(1)
    end
  end
end
