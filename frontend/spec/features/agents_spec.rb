# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Agents', js: true do
  before(:all) do
    @admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
  end

  before(:each) do
    login_user(@admin)
  end

  describe "agents merge" do
    it 'displays the full merge page without any errors' do
      now = Time.now.to_i
      agent_a = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
      ])

      agent_b = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
      ])

      run_index_round

      element = find('#global-search-box')
      element.fill_in with: agent_a['names'][0]['primary_name']
      find('#global-search-button').click

      element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
      within element do
        click_on 'Edit'
      end

      click_on 'Merge'

      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_b['names'][0]['primary_name']
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      expect(page).to have_text 'This record will be updated'
      expect(page).to have_text 'This record will be deleted'

      find('#agent_agent_record_identifiers__0__append_').click
      find('.preview-merge', match: :first).click

      within '#mergePreviewModal' do
        within '#agent_corporate_entity_agent_record_identifier_accordion' do
          elements = all('.card')
          elements.last.click
          expect(elements.last).to have_text agent_b['agent_record_identifiers'][0]['record_identifier']
        end
      end
    end

    it "merges record ids" do
      now = Time.now.to_i
      agent_a = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
      ])

      agent_b = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
      ])

      run_index_round

      element = find('#global-search-box')
      element.fill_in with: agent_a['names'][0]['primary_name']
      find('#global-search-button').click

      element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
      within element do
        click_on 'Edit'
      end

      click_on 'Merge'

      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_b['names'][0]['primary_name']
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      expect(page).to have_text 'This record will be updated'
      expect(page).to have_text 'This record will be deleted'

      find('#agent_agent_record_identifiers__0__append_').click
      find('.preview-merge', match: :first).click

      within '#mergePreviewModal' do
        within '#agent_corporate_entity_agent_record_identifier_accordion' do
          elements = all('.card')
          elements.last.click
          expect(elements.last).to have_text agent_b['agent_record_identifiers'][0]['record_identifier']
        end
      end
    end

    it "merges agent places" do
      now = Time.now.to_i
      agent_a = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
      ])

      agent_b = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
      ])

      run_index_round

      element = find('#global-search-box')
      element.fill_in with: agent_a['names'][0]['primary_name']
      find('#global-search-button').click

      element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
      within element do
        click_on 'Edit'
      end

      click_on 'Merge'

      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_b['names'][0]['primary_name']
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      expect(page).to have_text 'This record will be updated'
      expect(page).to have_text 'This record will be deleted'

      find('#agent_agent_places__0__append_').click
      find('.preview-merge', match: :first).click

      within '#mergePreviewModal' do
        within '#agent_corporate_entity_agent_place' do
          elements = all('.card')
          elements.last.click
          expect(elements.last).to have_text I18n.t("enumerations.place_role.#{agent_b['agent_places'][0]['place_role']}")
        end
      end
    end

    it "merges names" do
      now = Time.now.to_i
      agent_a = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
      ])

      agent_b = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
      ])

      run_index_round

      element = find('#global-search-box')
      element.fill_in with: agent_a['names'][0]['primary_name']
      find('#global-search-button').click

      element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
      within element do
        click_on 'Edit'
      end

      click_on 'Merge'

      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_b['names'][0]['primary_name']
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      expect(page).to have_text 'This record will be updated'
      expect(page).to have_text 'This record will be deleted'

      find('#agent_names__0__append_').click
      find('.preview-merge', match: :first).click

      within '#mergePreviewModal' do
        within '#agent_name_accordion' do
          elements = all('.card')
          elements.last.click
          expect(elements.last).to have_text agent_b['agent_places'][0]['primary_name']
        end
      end
    end
  end

  describe "disallows agents merge with related agents" do
    it 'tries to merge related agents and gets an error' do
      now = Time.now.to_i
      agent_a = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
      ])

      agent_b = create(:json_agent_corporate_entity_full_subrec, names: [
        build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
      ])

      run_index_round

      element = find('#global-search-box')
      element.fill_in with: agent_a['names'][0]['primary_name']
      find('#global-search-button').click

      element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
      within element do
        click_on 'Edit'
      end

      click_on 'Add Related Agent'

      using_wait_time(15) do
        element = find('#related-agents-container .related-agent-type.form-control')
        element.select 'Hierarchical Relationship'
        element = find('#token-input-agent_related_agents__1__ref_')
        element.fill_in with: agent_b['names'][0]['primary_name']
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click
      end

      # Click on save
      find('button', text: 'Save Corporate Entity', match: :first).click
      element = find('.alert.alert-success.with-hide-alert')
      expect(element.text).to eq 'Agent Saved'

      click_on 'Merge'
      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_b['names'][0]['primary_name']
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      element = find('.alert.alert-danger.with-hide-alert')
      expect(element.text).to eq 'These agents have a relationship. Remove relationship before proceeding with merge.'
    end
  end

  describe "agents record CRUD" do
    describe 'Full Agent Record' do
      it 'reports errors and warnings when creating an invalid Person Agent' do
        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-danger.with-hide-alert')
        expect(element.text).to eq 'Primary Part of Name - Property is required but was missing'
      end

      it 'reports a warning when Authority ID is provided without a Source' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__authority_id_')
        element.fill_in with: "Authority ID #{now}"
        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"
        select 'Local', from: 'agent_names__0__rules_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-warning.with-hide-alert')
        expect(element.text).to eq "Source - is required if there is an 'Authority ID'"
      end

      it 'auto generates Sort Name when other name fields upon save' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__authority_id_')
        element.fill_in with: "Authority ID #{now}"
        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"
        select 'Local', from: 'agent_names__0__rules_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-warning.with-hide-alert')
        expect(element.text).to eq "Source - is required if there is an 'Authority ID'"

        select 'Local', from: 'agent_names__0__source_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('h2')
        expect(element.text).to eq "Agent Name #{now} Agent"

        fill_in 'agent_names__0__rest_of_name_', with: "Rest of Agent Name #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Saved"

        element = find('h2')
        expect(element.text).to eq "Agent Name #{now}, Rest of Agent Name #{now} Agent"
      end

      it 'changing Direct Order updates Sort Name' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__authority_id_')
        element.fill_in with: "Authority ID #{now}"
        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"
        select 'Local', from: 'agent_names__0__rules_'
        select 'Local', from: 'agent_names__0__source_'
        fill_in 'agent_names__0__rest_of_name_', with: "Rest of Agent Name #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('h2')
        expect(element.text).to eq "Agent Name #{now}, Rest of Agent Name #{now} Agent"

        select 'Direct', from: 'agent_names__0__name_order_'
        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Saved"

        element = find('h2')
        expect(element.text).to eq "Rest of Agent Name #{now} Agent Name #{now} Agent"
      end

      it 'throws an error if no sort name is provided and auto gen is false' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__authority_id_')
        element.fill_in with: "Authority ID #{now}"
        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"
        select 'Local', from: 'agent_names__0__rules_'
        select 'Local', from: 'agent_names__0__source_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        find('#agent_names__0__sort_name_auto_generate_').click
        fill_in 'agent_names__0__sort_name_', with: ''

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-danger.with-hide-alert')
        expect(element.text).to eq 'Sort Name - Property is required but was missing'
      end

      it 'allows setting of a custom sort name' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        find('#agent_names__0__sort_name_auto_generate_').click
        fill_in 'agent_names__0__sort_name_', with: "Agent Sort Name #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('h2')
        expect(element.text).to eq "Agent Sort Name #{now} Agent"
      end

      it 'can add a secondary name and validations match index of name form' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        find('#agent_names__0__sort_name_auto_generate_').click
        fill_in 'agent_names__0__sort_name_', with: "Agent Sort Name #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('h2')
        expect(element.text).to eq "Agent Sort Name #{now} Agent"

        within '#agent_person_names' do
          click_on 'Add Name Form'
        end

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-danger.with-hide-alert')
        expect(element.text).to eq "Primary Part of Name - Property is required but was missing"
      end

      it 'can save a person and view readonly view of person' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        within '#agent_person_contact_details' do
          click_on 'Add Contact'
        end

        fill_in 'agent_agent_contacts__0__name_', with: "Contact Name #{now}"
        fill_in 'agent_agent_contacts__0__email_', with: "Email Address #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('h2')
        expect(element.text).to eq "Agent Name #{now} Agent"
      end

      it 'can add multiple telephone numbers' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        within '#agent_person_contact_details' do
          click_on 'Add Contact'
        end

        fill_in 'agent_agent_contacts__0__name_', with: "Contact Name #{now}"
        fill_in 'agent_agent_contacts__0__email_', with: "Email Address #{now}"

        within '#agent_agent_contacts__0__telephones_' do
          click_on 'Add Telephone Number'
          click_on 'Add Telephone Number'
        end
        fill_in 'agent_agent_contacts__0__telephones__0__number_', with: "Telephone Number 1 #{now}"
        fill_in 'agent_agent_contacts__0__telephones__0__ext_', with: "Telephone Extension 1 #{now}"
        fill_in 'agent_agent_contacts__0__telephones__1__number_', with: "Telephone Number 2 #{now}"
        fill_in 'agent_agent_contacts__0__telephones__1__ext_', with: "Telephone Extension 2 #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_contacts__0__telephones__0__number_').value).to eq "Telephone Number 1 #{now}"
        expect(find('#agent_agent_contacts__0__telephones__0__ext_').value).to eq "Telephone Extension 1 #{now}"
        expect(find('#agent_agent_contacts__0__telephones__1__number_').value).to eq "Telephone Number 2 #{now}"
        expect(find('#agent_agent_contacts__0__telephones__1__ext_').value).to eq "Telephone Extension 2 #{now}"
      end

      it 'reports errors when updating a Person Agent with invalid data' do
        agent = create(:agent_person)
        visit "agents/agent_person/#{agent.id}/edit"

        fill_in 'agent_names__0__primary_name_', with: ''

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-danger.with-hide-alert')
        expect(element.text).to eq 'Primary Part of Name - Property is required but was missing'
      end

      it 'can add a related agent' do
        agent_to_be_related = create(:agent_person)
        agent = create(:agent_person)
        run_index_round
        visit "agents/agent_person/#{agent.id}/edit"

        click_on 'Add Related Agent'

        element = find('select.related-agent-type')
        element.select 'Associative Relationship'
        fill_in 'token-input-agent_related_agents__1__ref_', with: agent_to_be_related.names.first['sort_name']
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Saved"

        element = find('#agent_related_agents__0_')
        expect(element).to have_text agent_to_be_related.names.first['sort_name']
      end

      it 'can remove contact details' do
        agent = create(:agent_person)
        visit "agents/agent_person/#{agent.id}/edit"

        find('#agent_person_contact_details .subrecord-form-remove', match: :first).click
        click_on 'Confirm Removal'

        expect(page).to_not have_css '#agent_agent_contacts__0__name_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Saved"
      end

      it 'can add an external document to an Agent' do
        now = Time.now.to_i

        agent = create(:agent_person)
        visit "agents/agent_person/#{agent.id}/edit"

        click_on 'Add External Document'

        fill_in 'agent_external_documents__0__title_', with: "External Document Title #{now}"
        fill_in 'agent_external_documents__0__location_', with: "External Document Location #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Saved"

        visit "agents/agent_person/#{agent.id}"

        elements = all('#agent_person_external_documents .external-document')
        expect(elements.length).to eq 1
        expect(elements[0]).to have_text "External Document Title #{now}"
        expect(elements[0]).to have_text "External Document Location #{now}"
      end

      it 'can add a date of existence to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Date'
        select 'Single', from: 'agent_dates_of_existence__0__date_type_structured_'
        fill_in 'agent_dates_of_existence__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_dates_of_existence__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a record identifier to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Record ID'
        fill_in 'agent_agent_record_identifiers__0__record_identifier_', with: "Agent Record Identifier #{now}"
        select 'Local', from: 'agent_agent_record_identifiers__0__source_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_record_identifiers__0__record_identifier_').value).to eq "Agent Record Identifier #{now}"
        expect(find('#agent_agent_record_identifiers__0__source_').value).to eq 'local'
      end

      it 'uses agent record identifier subrecord for authority id and rules if preset' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Record ID'
        fill_in 'agent_agent_record_identifiers__0__record_identifier_', with: "Agent Record Identifier #{now}"
        select 'Local', from: 'agent_agent_record_identifiers__0__source_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        run_index_round

        visit '/'

        click_on 'Browse'
        click_on 'Agents'
        element = find('#filter-text')
        element.fill_in with: "Agent Name #{now}"
        find('button[title="Filter by text"]').click
        element = find(:css, "tr", text: "Agent Name #{now}")
        expect(element).to have_text 'Local sources'
      end

      it 'can add a record control subrecord to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Record Info'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(page).to have_css '#agent_agent_record_controls__0_'
      end

      it 'can add an agency code to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Agency Code'
        fill_in 'agent_agent_other_agency_codes__0__maintenance_agency_', with: "Maintenance Agency #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_other_agency_codes__0__maintenance_agency_').value).to eq "Maintenance Agency #{now}"
      end

      it 'can add a conventions declaration to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Convention Declaration'
        select 'Local', from: 'agent_agent_conventions_declarations__0__name_rule_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_conventions_declarations__0__name_rule_').value).to eq 'local'
      end

      it 'uses agent conventions declaration subrecord for rules if present' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Convention Declaration'

        select 'Local', from: 'agent_agent_conventions_declarations__0__name_rule_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        run_index_round

        visit '/'

        click_on 'Browse'
        click_on 'Agents'

        element = find('#filter-text')
        element.fill_in with: "Agent Name #{now}"
        find('button[title="Filter by text"]').click
        element = find(:css, "tr", text: "Agent Name #{now}")
        expect(element).to have_text 'Local rules'
      end

      it 'can add maintenance history to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Event'
        select 'Created', from: 'agent_agent_maintenance_histories__0__maintenance_event_type_'
        fill_in 'agent_agent_maintenance_histories__0__event_date_', with: '1980-02-12'
        fill_in 'agent_agent_maintenance_histories__0__agent_', with: "Maintenance History Agent #{now}"
        select 'Machine', from: 'agent_agent_maintenance_histories__0__maintenance_agent_type_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_maintenance_histories__0__maintenance_event_type_').value).to eq 'created'
        expect(find('#agent_agent_maintenance_histories__0__event_date_').value).to eq '1980-02-12 00:00:00 UTC'
        expect(find('#agent_agent_maintenance_histories__0__agent_').value).to eq "Maintenance History Agent #{now}"
        expect(find('#agent_agent_maintenance_histories__0__maintenance_agent_type_').value).to eq 'machine'
      end

      it 'can add source entry to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Source'
        fill_in 'agent_agent_sources__0__source_entry_', with: "Source Entry #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_sources__0__source_entry_').value).to eq "Source Entry #{now}"
      end

      it 'can add alternate set to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Alternative Set'
        fill_in 'agent_agent_alternate_sets__0__set_component_', with: "Alternate Set #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_alternate_sets__0__set_component_').value).to eq "Alternate Set #{now}"
      end

      it 'can add entity ids to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Entity ID'
        fill_in 'agent_agent_identifiers__0__entity_identifier_', with: "Entity IDs #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_identifiers__0__entity_identifier_').value).to eq "Entity IDs #{now}"
      end

      it 'can add a name use date to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Use Date'
        select 'Single', from: 'agent_names__0__use_dates__0__date_type_structured_'
        fill_in 'agent_names__0__use_dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_names__0__use_dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a parallel name to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Parallel Name'
        fill_in 'agent_names__0__parallel_names__0__primary_name_', with: "Primary Part of Name #{now}"

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_names__0__parallel_names__0__primary_name_').value).to eq "Primary Part of Name #{now}"
      end

      it 'can add a name use date to a parallel name' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Parallel Name'
        fill_in 'agent_names__0__parallel_names__0__primary_name_', with: "Primary Part of Name #{now}"

        within '#agent_names__0__parallel_names_' do
          click_on 'Add Use Date'
        end

        select 'Single', from: 'agent_names__0__parallel_names__0__use_dates__0__date_type_structured_'
        fill_in 'agent_names__0__parallel_names__0__use_dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_names__0__parallel_names__0__primary_name_').value).to eq "Primary Part of Name #{now}"
        expect(find('#agent_names__0__parallel_names__0__use_dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add gender to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Gender'
        select 'Not Specified', from: 'agent_agent_genders__0__gender_'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_genders__0__gender_').value).to eq 'not_specified'
      end

      it 'can add a date to a gender' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Gender'
        select 'Not Specified', from: 'agent_agent_genders__0__gender_'
        within '#agent_agent_genders__0__dates_' do
          click_on 'Add Date'
        end

        element = find('#agent_agent_genders__0__dates__0__date_type_structured_')
        element.select 'Single'
        fill_in 'agent_agent_genders__0__dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_genders__0__dates__0__date_type_structured_').value).to eq 'single'
        expect(find('#agent_agent_genders__0__dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a note to a gender' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Gender'
        select 'Not Specified', from: 'agent_agent_genders__0__gender_'
        within '#agent_gender' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Text'

        page.execute_script("$('#agent_agent_genders__0__notes__0__content_').data('CodeMirror').setValue('Agent Gender Text #{now}')")
        page.execute_script("$('#agent_agent_genders__0__notes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_genders__0__gender_').value).to eq 'not_specified'
        expect(page.evaluate_script("$('#agent_agent_genders__0__notes__0__content_').data('CodeMirror').getValue()")).to eq "Agent Gender Text #{now}"
      end

      it 'can create an agent_place' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Geographic', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Place'
        select 'Place of Birth', from: 'agent_agent_places__0__place_role_'
        fill_in 'token-input-agent_agent_places__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_agent_places__0__subjects__0__ref__combobox')
        expect(element).to have_text "Subject Term #{now}"
      end

      it 'can add a date to an agent_place' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Geographic', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Place'
        select 'Place of Birth', from: 'agent_agent_places__0__place_role_'
        fill_in 'token-input-agent_agent_places__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_place' do
          click_on 'Add Date'
        end

        select 'Single', from: 'agent_agent_places__0__dates__0__date_type_structured_'
        fill_in 'agent_agent_places__0__dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_places__0__dates__0__date_type_structured_').value).to eq 'single'
        expect(find('#agent_agent_places__0__dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a note to an agent_place' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Geographic', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Place'
        select 'Place of Birth', from: 'agent_agent_places__0__place_role_'
        fill_in 'token-input-agent_agent_places__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_place' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Text'

        page.execute_script("$('#agent_agent_places__0__notes__0__content_').data('CodeMirror').setValue('Agent Place Text #{now}')")
        page.execute_script("$('#agent_agent_places__0__notes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(page.evaluate_script("$('#agent_agent_places__0__notes__0__content_').data('CodeMirror').getValue()")).to eq "Agent Place Text #{now}"
      end

      it 'can create an agent_occupation' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Occupation', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Occupation'
        fill_in 'token-input-agent_agent_occupations__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_agent_occupations__0__subjects__0__ref__combobox')
        expect(element).to have_text "Subject Term #{now}"
      end

      it 'can add a date to an agent_occupation' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Occupation', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Occupation'
        fill_in 'token-input-agent_agent_occupations__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_occupation' do
          click_on 'Add Date'
        end

        select 'Single', from: 'agent_agent_occupations__0__dates__0__date_type_structured_'
        fill_in 'agent_agent_occupations__0__dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_occupations__0__dates__0__date_type_structured_').value).to eq 'single'
        expect(find('#agent_agent_occupations__0__dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a note to an agent_occupation' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Occupation', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Occupation'
        fill_in 'token-input-agent_agent_occupations__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_occupation' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Text'

        page.execute_script("$('#agent_agent_occupations__0__notes__0__content_').data('CodeMirror').setValue('Agent Occupation Note #{now}')")
        page.execute_script("$('#agent_agent_occupations__0__notes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(page.evaluate_script("$('#agent_agent_occupations__0__notes__0__content_').data('CodeMirror').getValue()")).to eq "Agent Occupation Note #{now}"
      end

      it 'can create an agent_function' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Function', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Function'
        fill_in 'token-input-agent_agent_functions__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_agent_functions__0__subjects__0__ref__combobox')
        expect(element).to have_text "Subject Term #{now}"
      end

      it 'can add a date to an agent_function' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Function', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Function'
        fill_in 'token-input-agent_agent_functions__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_function' do
          click_on 'Add Date'
        end

        select 'Single', from: 'agent_agent_functions__0__dates__0__date_type_structured_'
        fill_in 'agent_agent_functions__0__dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_functions__0__dates__0__date_type_structured_').value).to eq 'single'
        expect(find('#agent_agent_functions__0__dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a note to an agent_function' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Function', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Function'
        fill_in 'token-input-agent_agent_functions__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_function' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Text'

        page.execute_script("$('#agent_agent_functions__0__notes__0__content_').data('CodeMirror').setValue('Agent Function Note #{now}')")
        page.execute_script("$('#agent_agent_functions__0__notes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(page.evaluate_script("$('#agent_agent_functions__0__notes__0__content_').data('CodeMirror').getValue()")).to eq "Agent Function Note #{now}"
      end

      it 'can create an agent_topic' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Topical', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Topic'
        fill_in 'token-input-agent_agent_topics__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_agent_topics__0__subjects__0__ref__combobox')
        expect(element).to have_text "Subject Term #{now}"
      end

      it 'can add a date to an agent_topic' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Topical', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Topic'
        fill_in 'token-input-agent_agent_topics__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_topic' do
          click_on 'Add Date'
        end

        select 'Single', from: 'agent_agent_topics__0__dates__0__date_type_structured_'
        fill_in 'agent_agent_topics__0__dates__0__structured_date_single__date_expression_', with: '1973'

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(find('#agent_agent_topics__0__dates__0__date_type_structured_').value).to eq 'single'
        expect(find('#agent_agent_topics__0__dates__0__structured_date_single__date_expression_').value).to eq '1973'
      end

      it 'can add a note to an agent_topic' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Subject'

        select 'Local', from: 'subject_source_'
        fill_in 'subject_terms__0__term_', with: "Subject Term #{now}"
        select 'Topical', from: 'subject_terms__0__term_type_'

        # Click on save
        find('button', text: 'Save Subject', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Subject Created"

        run_index_round

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        click_on 'Add Topic'
        fill_in 'token-input-agent_agent_topics__0__subjects__0__ref_', with: "Subject Term #{now}"
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

        within '#agent_person_agent_topic' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Text'

        page.execute_script("$('#agent_agent_topics__0__notes__0__content_').data('CodeMirror').setValue('Agent Topic Notes #{now}')")
        page.execute_script("$('#agent_agent_topics__0__notes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        expect(page.evaluate_script("$('#agent_agent_topics__0__notes__0__content_').data('CodeMirror').getValue()")).to eq "Agent Topic Notes #{now}"
      end

      it 'can add a Biog/Hist note to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        within '#agent_person_notes' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'Biographical / Historical'

        expect(page).to have_css '#agent_notes__0__label_'

        page.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').setValue('Biography/Historical Note #{now}')")
        page.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_person_notes')
        expect(element).to have_text "Biography/Historical Note #{now}"
      end

      it 'can add a General Context note to an Agent' do
        now = Time.now.to_i

        click_on 'Create'
        click_on 'Agent'
        click_on 'Person'

        element = find('#agent_names__0__primary_name_')
        element.fill_in with: "Agent Name #{now}"

        within '#agent_person_notes' do
          click_on 'Add Note'
        end

        element = find('select.top-level-note-type')
        element.select 'General Context'

        expect(page).to have_css '#agent_notes__0__label_'

        page.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').setValue('General Context Note #{now}')")
        page.execute_script("$('#agent_notes__0__subnotes__0__content_').data('CodeMirror').save()")

        # Click on save
        find('button', text: 'Save Person', match: :first).click
        element = find('.alert.alert-success.with-hide-alert')
        expect(element.text).to eq "Agent Created"

        element = find('#agent_person_notes')
        expect(element).to have_text "General Context Note #{now}"
      end

      it "displays the agent in the agent's index page" do
        agent = create(:agent_person)
        run_index_round

        visit '/agents?filter_term[]={"primary_type":"agent_person"}&sort=create_time+desc'

        elements = all('#tabledSearchResults tbody tr')
        expect(elements.length > 0).to eq true
        expect(elements[0]).to have_text agent.names.first['primary_name']
      end

      it 'returns agents in search results and shows their types correctly' do
        agent = create(:agent_person)
        run_index_round

        element = find('#global-search-box')
        element.fill_in with: agent.names.first['primary_name']
        find('#global-search-button').click

        elements = all('#tabledSearchResults tbody tr')
        expect(elements.length).to eq 1
        expect(elements[0]).to have_text 'Person'
        expect(elements[0]).to have_text agent.names.first['primary_name']
      end

      it 'will not delete a corp entity agent linked to a repo' do
        repository = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")

        run_index_round

        element = find('#global-search-box')
        element.fill_in with: repository.repo_code
        find('#global-search-button').click

        click_on 'Edit'
        click_on 'Delete'

        within '#confirmChangesModal' do
          click_on 'Delete'
        end

        element = find('.alert.alert-danger.with-hide-alert')
        expect(element.text).to eq "This agent is linked to a repository and can't be removed."
      end
    end
  end

  describe 'Light Agent Record' do
    before(:all) do
      @corpοrate_agent_full = create(:json_agent_corporate_entity_full_subrec)
      @corpοrate_agent_basic = create(:agent_corporate_entity)

      @repository = create(:repo, repo_code: "light_agent_record_test_#{Time.now.to_i}")

      @data_entry_user = create_user(@repository => ['repository-advanced-data-entry'])
    end

    before(:each) do
      login_user(@data_entry_user)
      select_repository(@repository)
      visit '/agents/agent_person/new'
    end

    it 'displays agent_record_identifiers in form' do
      expect(page).to have_css '#agent_person_agent_record_identifier'
    end

    it 'hides agent_record_control from form' do
      expect(page).to_not have_css '#agent_person_agent_record_control'
    end

    it 'hides agent_other_agency_codes from form' do
      expect(page).to_not have_css '#agent_person_agent_other_agency_codes'
    end

    it 'hides agent_conventions_declarations from form' do
      expect(page).to_not have_css '#agent_person_agent_conventions_declaration'
    end

    it 'hides agent_maintenance_histories from form' do
      expect(page).to_not have_css '#agent_person_agent_maintenance_history'
    end

    it 'hides agent_sources from form' do
      expect(page).to_not have_css '#agent_person_agent_sources'
    end

    it 'hides agent_alternate_sets from form' do
      expect(page).to_not have_css '#agent_person_agent_alternate_set'
    end

    it 'displays agent_identifiers in form' do
      expect(page).to have_css '#agent_person_agent_identifier'
    end

    it 'displays agent_names in form' do
      expect(page).to have_css '#agent_person_names'
    end

    it 'displays dates of existence in form' do
      expect(page).to have_css '#agent_person_dates_of_existence'
    end

    it 'hides agent_genders from form' do
      expect(page).to_not have_css '#agent_person_agent_gender'
    end

    it 'hides agent_places from form' do
      expect(page).to_not have_css '#agent_person_agent_place'
    end

    it 'hides agent_occupations from form' do
      expect(page).to_not have_css '#agent_person_agent_occupation'
    end

    it 'hides agent_functions from form' do
      expect(page).to_not have_css '#agent_person_agent_function'
    end

    it 'hides agent_topic from form' do
      expect(page).to_not have_css '#agent_person_agent_topic'
    end

    it 'hides used_languages from form' do
      expect(page).to_not have_css '#agent_person_agent_used_language'
    end

    it 'displays agent_contacts in form' do
      # not available to data entry user
      expect(page).to_not have_css '#agent_person_contact_details'
    end

    it 'displays agent_notes in form' do
      expect(page).to have_css '#agent_person_notes'
    end

    it 'displays agent_external_documents in form' do
      expect(page).to have_css '#agent_person_external_documents'
    end

    it 'hides agent_resources from form' do
      expect(page).to_not have_css '#agent_person_agent_resource'
    end

    it 'displays related_agents in form' do
      expect(page).to have_css '#related_agents'
    end

    it 'alerts light mode users that there is hidden record content' do
      visit "/agents/agent_corporate_entity/#{@corpοrate_agent_full.id}/edit"

      element = find('.alert.alert-warning.with-hide-alert')
      expect(element.text).to eq 'This agent has data that is only editable in Full mode. To enable it, ask your administrator to enable Full Mode on this instance and grant you Full Mode permission.'
    end

    it 'does not alert light mode users of hidden content when there is none' do
      visit "/agents/agent_corporate_entity/#{@corpοrate_agent_basic.id}/edit"

      element = find('h2')
      expect(element).to have_text @corpοrate_agent_basic.display_name['primary_name']
      expect(page).to_not have_css '.alert-warning'
    end
  end
end
