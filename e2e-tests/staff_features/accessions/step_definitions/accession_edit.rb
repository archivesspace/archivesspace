# frozen_string_literal: true

Given 'the Accession appears in the search results list' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'Edit')

    @accession_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end
end

Given 'the Accession is opened in the view mode' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'View')

    @accession_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end

  click_on 'View'
end

Then 'the Accession is updated with the new {string} as {string}' do |field, value|
  fill_in field, with: value
end

Then 'the Accession is opened in the edit mode' do
  uri = current_url.split('/')

  action = uri.pop
  accession_id = uri.pop

  expect(action).to eq 'edit'
  expect(accession_id).to eq @accession_id
end

Then 'the field {string} has value {string}' do |field, value|
  element = find_field(field, match: :first)

  expect(element.value.downcase.gsub(' ', '_')).to eq value.downcase.gsub(' ', '_')
end

Then 'the Accession Title field has the original value' do
  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"

  expect(page).to have_field('Title', with: "Accession Title #{@uuid}")
end

Then 'the Accession Date field has the original value' do
  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"

  expect(find('#accession_accession_date_').value).to eq ORIGINAL_ACCESSION_DATE
end

When 'the Accession Identifier field has the original value' do
  visit "#{STAFF_URL}/accessions/#{@accession_id}/edit"

  expect(page).to have_field('Identifier', with: "Accession #{@uuid}")
end

Given 'the Accession is opened in edit mode by User A' do
  visit "#{STAFF_URL}/accessions"

  fill_in 'filter-text', with: @uuid

  within '.search-filter' do
    find('button').click
  end

  search_result_rows = all('#tabledSearchResults tbody tr')
  expect(search_result_rows.length).to eq 1

  within search_result_rows[0] do
    element = find('a', text: 'Edit')

    @accession_id = URI.decode_www_form_component(element[:href]).split('/').pop
  end

  click_on 'Edit'
end

Given 'the Accession is opened in edit mode by User B' do
  @user_b_session = Capybara::Session.new(:firefox_alternative_session)

  @user_b_session.visit(STAFF_URL)

  @user_b_session.fill_in 'username', with: 'test'
  @user_b_session.fill_in 'password', with: 'test'
  @user_b_session.click_on 'Sign In'
  expect(@user_b_session).to have_text 'Welcome to ArchivesSpace'

  @user_b_session.click_on 'Browse'
  @user_b_session.click_on 'Accessions'

  @user_b_session.fill_in 'filter-text', with: @uuid

  @user_b_session.find('.search-filter button').click

  @user_b_session.click_on 'Edit'
end

When 'User A clicks on {string}' do |string|
  click_on string
end

When 'User A changes the {string} field' do |field|
  fill_in field, with: SecureRandom.uuid, match: :first
end

When 'User B changes the {string} field' do |field|
  @user_b_session.fill_in field, with: SecureRandom.uuid, match: :first
end

When 'User B clicks on {string}' do |string|
  @user_b_session.click_on string
end

Then 'User B sees a conflict message which indicates that User A is editing this record' do
  tries = 6
  element = nil

  loop do
    break if tries == 0

    begin
      tries -= 1

      element = @user_b_session.find('#form_messages .alert.alert-warning.update-monitor-error')
      expect(element.text).to eq 'This record is currently being edited by another user. Please contact the following users to ensure no conflicts occur: admin'
      break
    rescue Capybara::ElementNotFound
      sleep 3
    end
  end
end

Then 'User B sees the following conflict message' do |messages|
  messages.raw.each do |message|
    expect(@user_b_session).to have_text message[0]
  end
end

Then 'a new Instance is added to the Accession with the following values' do |form_values_table|
  instances = all('#accession_instances_ .subrecord-form-list li.subrecord-form-wrapper')

  expect(instances.length).to eq @accession_number_of_instances + 1

  instance = instances.last

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    if field == 'Top Container'
      expect(find('.top_container').text).to eq value
    else
      expect(instance.find_field(field, visible: true).value).to eq value.downcase.gsub(' ', '_')
    end
  end
end
