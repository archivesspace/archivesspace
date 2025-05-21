# frozen_string_literal: true

Before do
  @uuid = SecureRandom.uuid
end

Given 'an administrator user is logged in' do
  visit "#{STAFF_URL}/logout"

  login_admin

  ensure_test_repository_exists
  ensure_test_user_exists
  ensure_test_agent_exists
  ensure_test_subject_exists
  ensure_test_accession_exists
  ensure_test_classification_exists
  ensure_test_location_exists
  ensure_test_container_profile_exists
end

Given 'an archivist user is logged in' do
  login_archivist
end

Given 'a Repository with name {string} has been created' do |repository_name|
  visit "#{STAFF_URL}/repositories"

  fill_in 'filter-text', with: repository_name

  within '.search-filter' do
    find('button').click
  end

  begin
    find('tr', text: repository_name, match: :first)
  rescue Capybara::ElementNotFound
    visit "#{STAFF_URL}/repositories/new"
    fill_in 'Repository Short Name', with: repository_name
    fill_in 'Repository Name', with: repository_name

    click_on 'Save'
  end
end

When 'the user clicks on {string}' do |string|
  click_on_string string

  wait_for_ajax if current_url.include?("resources/#{@resource_id}/edit") ||
                   current_url.include?("digital_objects/#{@digital_object_id}/edit") ||
                   current_url.include?('merge_selector')
end

When 'the user hovers on {string} in the dropdown menu' do |string|
  within '.dropdown-menu' do
    element = find(:xpath, "//button[contains(text(), '#{string}')] | //a[contains(text(), '#{string}')]", match: :first)

    element.hover
  end
end

When 'the user clicks on {string} in the record toolbar' do |string|
  within '.record-toolbar' do
    click_on_string string
  end
end

When 'the user clicks on {string} in the modal' do |string|
  wait_for_ajax

  within '.modal-content' do
    click_on_string string
  end
end

When 'the user clicks on {string} in the transfer form' do |string|
  dropdown_menu = find('.transfer-form')

  within dropdown_menu do
    click_on_string string
  end
end

When 'the user clicks on {string} in the dropdown menu' do |string|
  dropdown_menu = find('.dropdown-menu', match: :first)

  within dropdown_menu do
    elements = dropdown_menu.all(:xpath, ".//*[contains(text(), '#{string}')]")

    elements.each do |element|
      if (element.tag_name == 'button' || element.tag_name == 'a' || element.tag_name == 'span') && element.text == string
        element.click
        break
      end
    end
  end
end

When 'the user clicks on {string} in the spawn dropdown menu' do |string|
  within '#spawn-dropdown' do
    click_on_string string
  end
end

When 'the user clicks on the first dropdown in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    find('.dropdown-toggle', match: :first).click
  end
end

When 'the user clicks on {string} in the {string} form' do |string, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    click_on string
  end
end

When 'the user clicks on {string} in the dropdown menu in the {string} form' do |string, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    dropdown_menu = find('.dropdown-menu')

    within dropdown_menu do
      click_on string
    end
  end
end

When 'the user fills in {string}' do |label|
  @uuid = SecureRandom.uuid if @uuid.nil?

  fill_in label, with: @uuid, match: :first
end

When 'the user fills in {string} in the modal' do |label|
  @uuid = SecureRandom.uuid if @uuid.nil?

  within '.modal-content' do
    fill_in label, with: @uuid, match: :first
  end
end

When 'the user clears the {string} field' do |label|
  fill_in label, with: '', match: :first
end

When 'the user fills in {string} with {string}' do |label, value|
  fill_in label, with: value, match: :first
end

When 'the user fills in {string} with {string} in the modal' do |label, value|
  within '.modal-content' do
    fill_in label, with: value, match: :first
  end
end

When 'the user fills in {string} with a unique identifier in the modal' do |label|
  within '.modal-content' do
    fill_in label, with: @uuid, match: :first
  end
end

When 'the user clicks on remove icon in the {string} form' do |form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    find('.subrecord-form-remove').click
    expect(page).to have_text 'Confirm Removal'
  end
end

When 'the user fills in {string} with {string} in the {string} form' do |label, value, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section', match: :first)
  expect(section[:id]).to_not eq nil

  within section do
    fill_in label, with: value
  end
end

When 'the user fills in {string} in the {string} form' do |label, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section', match: :first)
  expect(section[:id]).to_not eq nil

  within section do
    fill_in label, with: @uuid
  end
end

When 'the user fills in {string} with {string} and selects {string} in the {string} form' do |label, value, selected_value, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    fill_in label, with: value

    dropdown_items = all('li.dropdown-item a', text: selected_value).select do |entry|
      entry.text == selected_value
    end

    expect(dropdown_items.length).to eq 1
    expect(dropdown_items[0].text).to eq selected_value
    dropdown_items[0].click
  end
end

When 'the user selects {string} from {string}' do |option, label|
  select option, from: label, match: :first
end

When 'the user selects {string} in the modal' do |select_option|
  within '.modal-content' do
    find('#label').select select_option
  end
end

When 'the user selects {string} from {string} in the modal' do |option, label|
  wait_for_ajax

  within '.modal-content' do
    select option, from: label
  end
end

When 'the user selects {string} from {string} in the {string} form' do |option, label, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    select option, from: label
  end
end

When 'the user checks {string}' do |label|
  check label, match: :first
end

When 'the user unchecks {string}' do |label|
  uncheck label, match: :first
end

When 'the user changes the {string} field to {string}' do |field, value|
  field = find_field(field, match: :first)

  if field.tag_name == 'select'
    field.select value.strip
  else
    field.fill_in with: value
  end
end

When 'the user changes the {string} field' do |field|
  fill_in field, with: SecureRandom.uuid, match: :first
end

Then('the {string} created message is displayed') do |string|
  wait_for_ajax if current_url.include?('resources') || current_url.include?('digital_objects')

  expect(find('.alert.alert-success.with-hide-alert').text).to match(/^#{string}.*created.*$/i)

  @created_record_id = extract_created_record_id(string)
end

Then('the {string} updated message is displayed') do |string|
  wait_for_ajax if current_url.include?('resources') ||
                   current_url.include?('digital_objects') ||
                   current_url.include?('top_containers')

  expect(find('.alert.alert-success', match: :first).text).to match(/^#{string}.*updated$/i)
end

Then('the {string} saved message is displayed') do |string|
  wait_for_ajax if current_url.include? 'resources'

  expect(find('.alert.alert-success.with-hide-alert').text).to match(/^#{string}.*saved$/i)
end

Then('the {string} deleted message is displayed') do |string|
  expect(find('.alert.alert-success.with-hide-alert').text).to match(/^#{string}.*deleted$/i)
end

Then('the {string} published message is displayed') do |string|
  expect(find('.alert.alert-success.with-hide-alert').text).to match(/#{string} .* subrecords and components have been published.*$/i)
end

Then('the {string} unpublished message is displayed') do |string|
  expect(find('.alert.alert-success.with-hide-alert').text).to match(/#{string} .* subrecords and components have been unpublished.*$/i)
end

Then('the {string} merged message is displayed') do |string|
  expect(find('.alert.alert-success.with-hide-alert').text.downcase).to eq("#{string} Merged".downcase)
end

Then 'the following message is displayed' do |messages|
  messages.raw.each do |message|
    expect(page).to have_text message[0]
  end
end

Then('the {string} duplicated message is displayed') do |string|
  expect(find('.alert.alert-success.with-hide-alert').text).to match(/^#{string}.*duplicated.*$/i)
end

Then 'only the following info message is displayed' do |messages|
  expect(messages.raw.length).to eq 1

  messages.raw.each do |message|
    expect(page).to have_text message[0]
  end
end

Then 'the following error messages are displayed' do |messages|
  messages.raw.each do |message|
    expect(page).to have_text message[0]
  end
end

Then 'the following error message is displayed' do |messages|
  expect(messages.raw.length).to eq 1

  messages.raw.each do |message|
    expect(page).to have_text message[0]
  end
end

Then 'the {string} has value {string}' do |label, value|
  expect(page).to have_field(label, with: value)
end

Then 'the {string} has a unique value' do |label|
  expect(page).to have_field(label, with: @uuid, match: :first)
end

Then 'the {string} has selected value {string}' do |label, value|
  expect(page).to have_select(label, selected: value)
end

Then 'the {string} is checked' do |label|
  expect(page).to have_field(label, checked: true)
end

Then 'only the following error message is displayed' do |messages|
  expect(messages.raw.length).to eq 1

  messages.raw.each do |message|
    expect(page).to have_text message[0]
  end
end

Then 'the {string} section is displayed' do |section_heading|
  expect(all('section > h3').map(&:text)).to include(section_heading)
end

Given 'the Pre-populate Records option is checked in Repository Preferences' do
  visit "#{STAFF_URL}/repositories/new"

  fill_in 'repository_repository__repo_code_', with: "repository_test_default_values_#{@uuid}"
  fill_in 'repository_repository__name_', with: "Repository Test Default Values #{@uuid}"
  find('#repository_repository__publish_').check
  click_on 'Save'

  message = find('.alert')

  expect(message.text).to eq 'Repository Created'

  visit STAFF_URL

  click_on 'Select Repository'
  within '.dropdown-menu' do
    find('select').select "repository_test_default_values_#{@uuid}"

    click_on 'Select Repository'
  end

  expect(page).to have_text "The Repository repository_test_default_values_#{@uuid} is now active"

  find('#user-menu-dropdown').click
  within '.dropdown-menu' do
    click_on 'Repository Preferences (admin)'
  end

  find('#preference_defaults__default_values_').check
  expect(find('#preference_defaults__default_values_').checked?).to eq true

  click_on 'Save'
end

When 'the user clears {string} in the {string} form' do |label, form_title|
  section_title = find('h3', text: form_title)
  section = section_title.ancestor('section')
  expect(section[:id]).to_not eq nil

  within section do
    select '', from: label
  end
end

When 'the user clicks on the dropdown in the merge dropdown form' do
  within '#merge-dropdown .dropdown-menu.merge-form' do
    find('.btn.btn-default.dropdown-toggle').click
  end
end

When 'the user clicks on {string} in the merge dropdown form' do |string|
  within '#merge-dropdown .dropdown-menu.merge-form' do
    click_on string
  end
end

Then 'the button has text {string}' do |text|
  expect(page).to have_text text
end

When 'the user clicks on the gear icon' do
  within '.repo-container' do
    find('.btn.btn-default.navbar-btn.dropdown-toggle').click
  end
end

When 'the user selects {string} from {string} in the first row of the Rapid Data Entry table' do |option, label|
  table_header_cells = all('.fieldset-labels .kiketable-th-text')

  label_position = 0
  table_header_cells.each_with_index do |header, index|
    label_position = index if header.text == label
  end

  label_position += 1
  expect(label_position).to_not eq 0

  table_field_cells = all('#rdeTable tbody td')
  field_cell = table_field_cells[label_position]
  field_cell_select = field_cell.find('select')
  field_cell_select.select option
end

When 'the user fills in {string} with {string} in the first row of the Rapid Data Entry table' do |label, value|
  table_header_cells = all('.fieldset-labels .kiketable-th-text')

  label_position = 0
  table_header_cells.each_with_index do |header, index|
    label_position = index if header.text == label
  end

  label_position += 1
  expect(label_position).to_not eq 0

  table_field_cells = all('#rdeTable tbody td')
  field_cell = table_field_cells[label_position]
  field_cell_input = field_cell.find('input')
  field_cell_input.fill_in with: value
end

When 'the user unchecks the {string} checkbox in the dropdown menu' do |label|
  uncheck label
end

Then 'the {string} column is no longer visible in the Rapid Data Entry table' do |string|
  expect(page).to_not have_css('.fieldset-label.sticky.kiketable-th', text: string)
end

Then 'a new row with the following data is added to the Rapid Data Entry table' do |form_values_table|
  table_header_cells = all('.fieldset-labels .kiketable-th-text')
  table_field_rows = all('#rdeTable tbody tr')

  expect(table_field_rows.length).to eq 2

  form_values_hash = form_values_table.rows_hash
  form_values_hash.each do |field, value|
    field_position = 0
    table_header_cells.each_with_index do |header, index|
      field_position = index if header.text == field
    end
    field_position += 1
    expect(field_position).to_not eq 0

    table_field_cells = table_field_rows[1].all('td')
    field_cell = table_field_cells[field_position]

    expect(field_cell.find('input, select, textarea').value.downcase.gsub(' ', '_')).to eq value.downcase.gsub(' ', '_')
  end
end

Given 'a Rapid Data Entry template has been created' do
  click_on 'Rapid Data Entry'
  click_on 'Save as Template'
  fill_in 'Template name', with: "RDE Template  #{@uuid}"
  click_on 'Save Template'
end

When 'the user checks the created Rapid Data Entry template' do
  find('label', text: "RDE Template #{@uuid}").click
end

Then 'the {string} button is enabled' do |text|
  buttons = all('button', text: text)

  buttons.each do |button|
    expect(button.disabled?).to eq false
  end
end

Then 'the {string} button is disabled' do |text|
  buttons = all('button', text: text)

  buttons.each do |button|
    expect(button.disabled?).to eq true
  end
end
