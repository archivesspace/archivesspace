# frozen_string_literal: true

Given 'a Resource with a Top Container has been created' do
  visit "#{STAFF_URL}/resources/new"

  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource #{@uuid}"
  find('#resource_publish_').check
  select 'Class', from: 'resource_level_'

  click_on 'Add Container Instance'
  select 'Accession', from: 'resource_instances__0__instance_type_'

  within '#resource_instances__0__sub_container__top_container__ref__combobox' do
    find('button').click

    click_on 'Create'
  end

  fill_in 'top_container_indicator_', with: @uuid
  click_on 'Create and Link'

  languages = all('#resource_lang_materials_ .subrecord-form-list li')
  click_on 'Add Language' if languages.length == 0
  element = find('#resource_lang_materials__0__language_and_script__language_')
  element.send_keys(ORIGINAL_LANGUAGE)
  element.send_keys(:tab)

  select 'Single', from: 'resource_dates__0__date_type_'
  fill_in 'resource_dates__0__begin_', with: ORIGINAL_RESOURCE_DATE
  @resource_number_of_dates = 1

  fill_in 'resource_extents__0__number_', with: '10'
  select 'Cassettes', from: 'resource_extents__0__extent_type_'
  @resource_number_of_extents = 1

  element = find('#resource_finding_aid_language_')
  element.send_keys('ENG')
  element.send_keys(:tab)

  element = find('#resource_finding_aid_script_')
  element.send_keys('Latin')
  element.send_keys(:tab)

  click_on 'Save'

  expect(find('.alert.alert-success.with-hide-alert').text).to have_text "Resource Resource #{@uuid} created"

  uri_parts = current_url.split('/')
  uri_parts.pop
  @resource_id = uri_parts.pop

  top_container = find('.top_container')
  data_content = top_container[:'data-content']
  split = data_content.split('/')
  split.pop
  text_containing_id = split.pop
  @top_container_id = text_containing_id.scan(/\d+/).first
end

Given 'the Resource is opened in the view mode' do
  visit "#{STAFF_URL}/resources/#{@resource_id}"
end

Given 'the Resource is opened in edit mode' do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  wait_for_ajax
end

Given 'the Resource is published' do
  expect(find('#resource_publish_').checked?).to eq true
end

Given 'the {string} button is displayed' do |button_text|
  expect(page).to have_css('a', text: button_text)
end

Then 'the Resource opens on a new tab in the public interface' do
  expect(page.windows.size).to eq 2
  switch_to_window(page.windows[1])

  tries = 0

  while current_url == 'about:blank'
    break if tries == 3

    tries += 1
    sleep 1
  end

  expect(current_url).to eq "#{PUBLIC_URL}/repositories/#{@repository_id}/resources/#{@resource_id}"
  expect(page).to have_text "Resource #{@uuid}"
end

When 'the user filters by text with the Resource title' do
  expect(find('h2').text).to eq 'Resources'

  fill_in 'Filter by text', with: @uuid
  find('.search-filter button').click

  rows = []
  checks = 0

  while checks < 5
    checks += 1

    begin
      rows = all('tr', text: "Resource #{@uuid}")
    rescue Selenium::WebDriver::Error::JavascriptError
      sleep 1
    end

    break if rows.length == 1
  end
end

Then 'the Resource is in the search results' do
  expect(page).to have_css('tr', text: @uuid)
end

Then 'the Resource view page is displayed' do
  expect(find('h2').text).to eq "Resource #{@uuid} Resource"
end
