# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Detailed Merging of Agents', js: true do
  context 'when user is admin' do
    let(:now) { Time.now.to_i }
    let(:agent_a) do
      create(:json_agent_corporate_entity_full_subrec, names: [
               build(:json_name_corporate_entity, primary_name: "Agent Name A #{now}")
             ])
    end
    let(:agent_b) do
      create(:json_agent_corporate_entity_full_subrec, names: [
               build(:json_name_corporate_entity, primary_name: "Agent Name B #{now}")
             ])
    end

    before(:each) do
      agent_a
      agent_b
      run_index_round
      login_admin
    end


    it 'displays the full merge page without any errors' do
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

    describe "disallows agents merge with related agents" do
      it 'tries to merge related agents and gets an error' do
        element = find('#global-search-box')
        element.fill_in with: agent_a['names'][0]['primary_name']
        find('#global-search-button').click

        element = find(:css, "table tr", text: agent_a['names'][0]['primary_name'])
        within element do
          click_on 'Edit'
        end

        click_on 'Add Related Agent'

        element = find('#related-agents-container .related-agent-type.form-control')
        element.select 'Hierarchical Relationship'
        element = find('#token-input-agent_related_agents__1__ref_')
        element.fill_in with: agent_b['names'][0]['primary_name']
        dropdown_items = all('li.token-input-dropdown-item2')
        dropdown_items.first.click

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

        expect(page).to have_css('.alert.alert-danger.with-hide-alert', visible: true, text: 'These agents have a relationship. Remove relationship before proceeding with merge.')
      end
    end
  end

  context 'when the user does not have permission to view agent contacts' do
    let!(:repository) { create(:repo, repo_code: "agents_test_#{Time.now.to_i}") }
    let!(:agent) { create(:agent_person, agent_contacts: [build(:json_agent_contact)]) }
    let!(:agent_source) { create(:agent_person) }

    # has manage_agent_record but no view_agent_contact_record permissions
    let(:user) { create_user(repository => ['repository-advanced-data-entry']) }

    it 'prevents merging of agents containing address data' do
      login_admin
      select_repository(repository)

      visit "/agents/#{agent['jsonmodel_type']}/#{agent.id}/edit"

      element = find('#agent_agent_contacts__0__name_')
      expect(element.value).to_not be_nil

      element = find('#agent_agent_contacts__0__telephones__0__number_')
      expect(element.value).to_not be_nil

      element = find('#agent_agent_contacts__0__notes__0__date_of_contact_')
      expect(element.value).to_not be_nil

      visit "/groups"

      row = find(:xpath, "//tr[contains(., 'repository-advanced-data-entry')]")
      within row do
        click_on 'Edit'
      end

      expect(page).to have_text("Advanced Data Entry users of the #{repository.repo_code} repository")

      find('#merge_agents_and_subjects').click

      find('button', text: 'Save Group', match: :first).click

      visit 'logout'

      run_periodic_index

      login_user(user)

      visit "/agents/#{agent['jsonmodel_type']}/#{agent.id}/edit"

      click_on 'Merge'

      element = find('#token-input-merge_ref_')
      element.fill_in with: agent_source['names'][0]['primary_name']

      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click

      find('.merge-button').click

      within '#confirmChangesModal' do
        click_on 'Compare Agents'
      end

      find('button.do-merge', text: 'Merge', match: :first).click

      expect(page).to have_selector('.alert.alert-danger.with-hide-alert', visible: true, text: 'Merging agent(s) could not complete: The merge cannot be completed because one or more of the agents has contact details you do not have permission to access.')
    end
  end
end
