# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'factories'

describe 'Events', js: true do

  before(:all) do
    @repo = create :repo, repo_code: "default_values_test_#{Time.now.to_i}"
    set_repo @repo
    @resource = create :resource
  end

  it 'retains the linked resource when adding additional events via +1 button' do
    login_admin
    select_repository @repo
    visit "/resources/#{@resource.id}"
    find('button.add-event-action').click
    find('button.add-event-button').click

    expect(page).to have_content 'New Event'
    expect(page).to have_selector 'div.resource'
    select 'Single', from: 'event[date][date_type]'
    fill_in 'event[date][begin]', with: '2023'
    select 'Authorizer', from: 'event[linked_agents][0][role]'
    fill_in 'token-input-event_linked_agents__0__ref_', with: 'test'

    # Need to wait for evidence of dropdown populating before sending enter to select the agent.
    # This is accomplished by waiting for the aria attribute to show up. (TODO: better way?)
    # After that, click the +1, then wait for the form submission to complete, otherwise it will
    # immediately find the the linked resource div on the current page and short-circuit the test.
    # Easiest way is probably just to look for the success flash.
    expect(page).to have_css '#token-input-event_linked_agents__0__ref_[aria-controls]'
    find(id: 'token-input-event_linked_agents__0__ref_').send_keys(:enter)
    click_button id: 'createPlusOne'
    expect(page).to have_content 'Event Created'
    expect(page).to have_selector 'div.resource'
  end

end
