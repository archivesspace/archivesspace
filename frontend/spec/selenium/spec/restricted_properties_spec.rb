# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Restricted properties' do
  before(:all) do
    @repo = create(:repo, repo_code: "agents_test_#{Time.now.to_i}")
    @user = create_user(@repo => ['repository-advanced-data-entry'])
    @agent = create(:agent_person)
    @restricted_property = 'agent_contacts'
    @driver = Driver.get.login_to_repo(@user, @repo)
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
end
