# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Restricted properties' do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")
    @user = create_user(@repo => ['repository-advanced-data-entry'])
    @agent = create(:agent_person)
    @agent_victim = create(:agent_person)
    @restricted_property = 'agent_contacts'
    @driver = Driver.get.login_to_repo(@user, @repo)
    run_index_round
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'Updating a record with restricted properties retains the restricted data' do
    expect(@agent[@restricted_property].count).to eq 1
    @driver.navigate.to("#{$frontend}/agents/#{@agent['jsonmodel_type']}/#{@agent.id}/edit")
    @driver.find_hidden_element(css: '#agent_restricted_properties___')
    @driver.find_element(css: "form#agent_form button[type='submit']").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Agent Saved/)

    @driver.logout.login_to_repo($admin, @repo_to_manage)
    @driver.navigate.to("#{$frontend}/agents/#{@agent['jsonmodel_type']}/#{@agent.id}/edit")
    expect(@driver.find_element(id: 'agent_agent_contacts__0__name_')).not_to be_nil
    expect(@driver.find_element(id: 'agent_agent_contacts__0__telephones__0__number_')).not_to be_nil
    expect(@driver.find_element(id: 'agent_agent_contacts__0__notes__0__date_of_contact_')).not_to be_nil
  end

  it 'Prevents merging of agents containing restricted data' do
    # first add merge permission to our group (that cannot view contact details)
    @driver.logout.login_to_repo($admin, @repo)
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Manage Groups')
    row = @driver.find_element_with_text('//tr', /repository-advanced-data-entry/)
    row.click_and_wait_until_gone(:link, 'Edit')
    @driver.find_element(:xpath, '//input[@id="merge_agents_and_subjects"]').click
    @driver.click_and_wait_until_gone(css: 'button[type="submit"]')

    # now attempt the merge
    @driver.logout.login_to_repo(@user, @repo_to_manage)
    @driver.navigate.to("#{$frontend}/agents/#{@agent['jsonmodel_type']}/#{@agent.id}/edit")
    @driver.find_element(:link, 'Merge').click
    input = @driver.find_element(:id, 'token-input-merge_ref_')
    @driver.typeahead_and_select(input, @agent_victim['names'][0]['primary_name'])
    @driver.find_element(class: 'merge-button').click
    @driver.find_element(id: 'confirmButton').click
    @driver.find_element_with_text('//div[contains(@class, "alert-danger")]', /merge cannot be completed/)
  end
end
