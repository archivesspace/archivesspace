# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'factories'

describe 'Events', js: true do

  before(:all) do
    @now = Time.now.to_i
    @repository = create :repo, repo_code: "default_values_test_#{Time.now.to_i}"
    set_repo @repository
    @resource = create :resource, title: "Resource Title #{@now}"
    @accession = create :accession, title: "Accession Title #{@now}"

    name_string = "Agent Name #{@now}"

    name = build(
      :name_person,
      name_order: 'inverted',
      primary_name: name_string,
      rest_of_name: name_string,
      sort_name: name_string
    )

    @agent = create(:agent_person, names: [name])

    @manager_user = create_user(@repository => ['repository-managers'])

    run_index_round
  end

  it 'retains the linked record when adding additional events via +1 button' do
    login_admin
    select_repository @repository
    visit "/resources/#{@resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true)
      expect(find('h2').text).to eq "#{@resource.title} Resource"
    end

    click_button('Add Event')

    using_wait_time(15) do
      expect(page).to have_selector('.dropdown-menu.add-event-form', visible: true)
    end

    within '#form_add_event' do
      click_button('Add Event')
    end

    expect(page).to have_content 'New Event'
    expect(page).to have_selector 'div.resource'
    select 'Single', from: 'event[date][date_type]'
    fill_in 'event[date][begin]', with: '2023'
    select 'Authorizer', from: 'event[linked_agents][0][role]'

    # Need to wait for evidence of dropdown populating before sending enter to select the agent.
    # This is accomplished by waiting for the aria attribute to show up. (TODO: better way?)
    # After that, click the +1, then wait for the form submission to complete, otherwise it will
    # immediately find the the linked resource div on the current page and short-circuit the test.
    # Easiest way is probably just to look for the success flash.
    fill_in 'token-input-event_linked_agents__0__ref_', with: 'test'
    expect(page).to have_css '#token-input-event_linked_agents__0__ref_[aria-controls]'
    find(id: 'token-input-event_linked_agents__0__ref_').send_keys(:enter)

    click_button id: 'createPlusOne'
    expect(page).to have_content 'Event Created'
    expect(page).to have_selector 'div.resource'
  end

  it 'adds an event via +1 button when using Create -> Event without a previously linked record' do
    login_admin
    select_repository @repository

    click_button 'Create'
    click_on 'Event'

    expect(page).to have_content 'New Event'
    select 'Single', from: 'event[date][date_type]'
    fill_in 'event[date][begin]', with: '2023'
    select 'Authorizer', from: 'event[linked_agents][0][role]'

    # see comment in example above
    fill_in 'token-input-event_linked_agents__0__ref_', with: 'test'
    expect(page).to have_css '#token-input-event_linked_agents__0__ref_[aria-controls]'
    find(id: 'token-input-event_linked_agents__0__ref_').send_keys(:enter)

    select 'Source', from: 'event[linked_records][0][role]'
    fill_in 'token-input-event_linked_records__0__ref_', with: 'Resource Title'
    expect(page).to have_css '#token-input-event_linked_records__0__ref_[aria-controls]'
    find(id: 'token-input-event_linked_records__0__ref_').send_keys(:enter)

    click_button id: 'createPlusOne'
    expect(page).to have_content 'Event Created'
    expect(page).to have_current_path '/events/new'
  end

  it 'creates an event and links it to an agent and an agent as a source' do
    now = Time.now.to_i

    login_user @manager_user
    select_repository @repository

    click_on 'Create'
    click_on 'Event'

    select 'Accession', from: 'event_event_type_'
    select 'Pass', from: 'event_outcome_'
    fill_in 'event_outcome_note_', with: "Event outcome note #{now}"
    select 'Single', from: 'event_date__date_type_'
    fill_in 'event_date__begin_', with: '1776'
    select 'Recipient', from: 'event_linked_agents__0__role_'

    fill_in 'token-input-event_linked_agents__0__ref_', with: 'test'
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    select 'Source', from: 'event_linked_records__0__role_'

    fill_in 'token-input-event_linked_records__0__ref_', with: "Agent Name #{@now}"
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Event', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Event Created'

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Agents'

    fill_in 'filter-text', with: "Agent Name #{@now}"
    find('.sidebar input.text-filter-field + div button').click
    element = find(:xpath, "//tr[contains(., 'Agent Name #{@now}')]")

    within element do
      click_on 'View'
    end

    expect(page).to have_css('td', text: 'accession')
  end

  it 'creates an event and links it to an agent and accession' do
    now = Time.now.to_i

    login_user @manager_user
    select_repository @repository

    click_on 'Create'
    click_on 'Event'

    select 'Virus Check', from: 'event_event_type_'
    select 'Pass', from: 'event_outcome_'
    fill_in 'event_outcome_note_', with: "Event outcome note #{now}"
    select 'Single', from: 'event_date__date_type_'
    fill_in 'event_date__begin_', with: '2000-01-01'
    select 'Recipient', from: 'event_linked_agents__0__role_'

    fill_in 'token-input-event_linked_agents__0__ref_', with: "Agent Name #{@now}"
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    select 'Source', from: 'event_linked_records__0__role_'

    fill_in 'token-input-event_linked_records__0__ref_', with: @accession.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Event', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Event Created'
  end

  it 'can add an external document to an Event' do
    now = Time.now.to_i

    login_user @manager_user
    select_repository @repository

    click_on 'Create'
    click_on 'Event'

    select 'Virus Check', from: 'event_event_type_'
    select 'Pass', from: 'event_outcome_'
    fill_in 'event_outcome_note_', with: "Event outcome note #{now}"
    select 'Single', from: 'event_date__date_type_'
    fill_in 'event_date__begin_', with: '2000-01-01'
    select 'Recipient', from: 'event_linked_agents__0__role_'

    fill_in 'token-input-event_linked_agents__0__ref_', with: "Agent Name #{@now}"
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    select 'Source', from: 'event_linked_records__0__role_'

    fill_in 'token-input-event_linked_records__0__ref_', with: @accession.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Event', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Event Created'

    click_on 'Add External Document'
    fill_in 'event_external_documents__0__title_', with: "External Document Title #{now}"
    fill_in 'event_external_documents__0__location_', with: "External Document Location #{now}"

    # Click on save
    find('button', text: 'Save Event', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Event Saved'

    elements = all('#event_external_documents_ .subrecord-form-wrapper')
    expect(elements.length).to eq 1
    expect(find('#event_external_documents__0__title_').value).to eq "External Document Title #{now}"
    expect(find('#event_external_documents__0__location_').value).to eq "External Document Location #{now}"
  end

  it 'should be searchable' do
    now = Time.now.to_i

    login_user @manager_user
    select_repository @repository

    click_on 'Create'
    click_on 'Event'

    select 'Virus Check', from: 'event_event_type_'
    select 'Pass', from: 'event_outcome_'
    fill_in 'event_outcome_note_', with: "Event outcome note #{now}"
    select 'Single', from: 'event_date__date_type_'
    fill_in 'event_date__begin_', with: '2000-01-01'
    select 'Recipient', from: 'event_linked_agents__0__role_'

    fill_in 'token-input-event_linked_agents__0__ref_', with: "Agent Name #{@now}"
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    select 'Source', from: 'event_linked_records__0__role_'

    fill_in 'token-input-event_linked_records__0__ref_', with: @accession.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Event', match: :first).click
    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'Event Created'

    run_index_round

    find('#global-search-button').click

    within '.search-listing-filter' do
      click_on 'Event'
    end

    expect(page).to have_text 'Search Results'
    expect(page).to have_text "Agent Name #{@now}"
  end

  it 'can export a csv of browse list Events that includes record link names' do
    now = Time.now.to_i

    login_user @manager_user
    select_repository @repository

    # Delete any existing CSV files
    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    csv_files.each do |file|
      File.delete(file)
    end

    click_on 'Browse'
    click_on 'Events'

    click_on 'Download CSV'

    csv_files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    expect(csv_files.length).to eq(1)

    csv = File.read(csv_files[0])
    expect(csv).to include("Agent Name #{@now}")
  end
end
