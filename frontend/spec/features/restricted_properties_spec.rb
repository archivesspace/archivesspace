# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Restricted properties', js: true do
  let!(:repository) { create(:repo, repo_code: "agents_test_#{Time.now.to_i}") }
  let(:user) { create_user(repository => ['repository-advanced-data-entry']) }
  let!(:agent) { create(:agent_person) }
  let!(:agent_source) { create(:agent_person) }
  let(:restricted_property) { 'agent_contacts' }

  xit 'updates a record with restricted properties retains the restricted data' do
    login_user(user)
    select_repository(repository)

    expect(agent[restricted_property].count).to eq 1

    visit "/agents/#{agent['jsonmodel_type']}/#{agent.id}/edit"

    find('#agent_restricted_properties___', visible: false)

    # Click on save
    find('button', text: 'Save Person', match: :first).click

    expect(page).to have_text 'Agent Saved'

    visit 'logout'

    login_admin

    select_repository(repository)

    visit "/agents/#{agent['jsonmodel_type']}/#{agent.id}/edit"

    element = find('#agent_agent_contacts__0__name_')
    expect(element.value).to_not be_nil

    element = find('#agent_agent_contacts__0__telephones__0__number_')
    expect(element.value).to_not be_nil

    element = find('#agent_agent_contacts__0__notes__0__date_of_contact_')
    expect(element.value).to_not be_nil
  end

  xit 'prevents merging of agents containing restricted data' do
    login_admin
    select_repository(repository)

    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'

    row = find(:xpath, "//tr[contains(., 'repository-advanced-data-entry')]")
    within row do
      click_on 'Edit'
    end

    expect(page).to have_text("Advanced Data Entry users of the #{repository.repo_code} repository")

    find('#merge_agents_and_subjects').click

    # Click on save
    find('button', text: 'Save Group', match: :first).click

    visit 'logout'

    login_user(user)

    select_repository(repository)

    visit "/agents/#{agent['jsonmodel_type']}/#{agent.id}/edit"

    click_on 'Merge'

    element = find('#token-input-merge_ref_')
    element.fill_in with: agent_source['names'][0]['primary_name']
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    within '#form_merge' do
      click_on 'Merge'
    end

    within '#confirmChangesModal' do
      click_on 'Compare Agents'
    end

    expect(page).to have_text 'The merge cannot be completed because one or more of the agents has contact details you do not have permission to access.'
  end
end
