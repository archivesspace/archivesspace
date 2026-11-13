# frozen_string_literal: true

Given 'the user selects {string} in the List Name dropdown menu' do |string|
  select string, from: 'enum_selector' do
    wait_for_ajax
  end
end

Given 'the value {string} is added to the list' do |string|
  expect(page).to have_css('tbody tr td', text: string)
end

Given 'a value has been added to the {string} controlled value list' do |list|
  @controlled_value_list = list
  @controlled_value = "suppressed_#{@uuid}"

  visit "#{STAFF_URL}/enumerations"
  select list, from: 'enum_selector'
  wait_for_ajax

  click_on 'Create Value'
  within '.modal-content' do
    fill_in 'enumeration_value_', with: @controlled_value
    click_on 'Create Value'
  end

  rows = []
  checks = 0

  while checks < 5
    checks += 1

    begin
      rows = all('tbody tr', text: @controlled_value)
    rescue Selenium::WebDriver::Error::JavascriptError
      rows = []
    end

    break if rows.length == 1

    sleep 1
  end

  expect(rows.length).to eq 1
end

When 'the added controlled value is suppressed' do
  visit "#{STAFF_URL}/enumerations"
  select @controlled_value_list, from: 'enum_selector'
  wait_for_ajax

  within(find('tbody tr', text: @controlled_value)) { click_on 'Suppress' }

  expect(page).to have_text 'Value Updated'
end

When 'the user selects the added controlled value from {string} in the {string} form' do |label, form_title|
  within form_section(form_title) do
    select @controlled_value, from: label
  end
end

Then 'the {string} has the suppressed controlled value selected in the {string} form' do |label, form_title|
  within form_section(form_title) do
    expect(page).to have_select(label, selected: "#{@controlled_value} (suppressed)")
  end
end

Then 'the added controlled value is not offered in {string} in the {string} form' do |label, form_title|
  within form_section(form_title) do
    expect(page).to have_select(label)
    expect(page).not_to have_css('option', text: @controlled_value)
  end
end

Then 'the suppressed controlled value warning is displayed for {string}' do |list_name|
  expect(page).to have_css('.alert.alert-warning',
                           text: "This record was saved with suppressed controlled values: #{list_name}: #{@controlled_value}")
end

Then 'the suppressed controlled value is displayed' do
  expect(page).to have_text "#{@controlled_value} (suppressed)"
end
