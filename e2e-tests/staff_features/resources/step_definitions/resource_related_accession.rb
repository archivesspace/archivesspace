# frozen_string_literal: true

When('the user clicks the dropdown toggle for related accessions') do
  within '#resource_related_accessions__0__ref__combobox' do
    find('button').click
  end
  wait_for_ajax
end

When('the user clicks {string} in the dropdown menu') do |menu_item|
  within '#resource_related_accessions__0__ref__combobox' do
    within '.dropdown-menu' do
      click_on menu_item
    end
  end
  wait_for_ajax
end

Then('the related accession creation modal should be displayed') do
  expect(page).to have_css('#resource_related_accessions__0__ref__modal', visible: true)
  within '#resource_related_accessions__0__ref__modal' do
    expect(page).to have_content('Accession')
    expect(page).to have_button('Create and Link')
  end
end

When('the user fills in the inline accession form') do |table|
  @accession_data = {}

  within '#resource_related_accessions__0__ref__modal' do
    table.hashes.each do |row|
      field = row['field']
      value = row['value']

      value = "ACC_#{Time.now.to_i}" if field == 'Identifier'

      normalized_key = field.downcase.gsub(' ', '_')
      @accession_data[normalized_key] = value

      case field
      when 'Identifier'
        fill_in 'accession_id_0_', with: value
      when 'Title'
        fill_in 'accession_title_', with: value
      when 'Accession Date'
        fill_in 'accession_accession_date_', with: value
      end
    end
  end
end

Then('the modal should close') do
  expect(page).not_to have_css('#resource_related_accessions__0__ref__modal', visible: true)
end

Then('the accession should appear in the related accessions linker') do
  within '#resource_related_accessions__0__ref__combobox' do
    title = @accession_data['title'] || 'Test Related Accession'
    expect(page).to have_text(title)
  end
end

When('the user saves the resource') do
  find('button', text: 'Save Resource', match: :first).click
  wait_for_ajax
end

Then('the resource created message is displayed') do
  expect(page).to have_css('.alert.alert-success', text: /Resource.*created/i)
end

Then('the resource updated message is displayed') do
  expect(page).to have_css('.alert.alert-success', text: /Resource.*updated/i)
end

Then('the related accession link should be preserved') do
  within '#resource_related_accessions__0__ref__combobox' do
    title = @accession_data['title'] || 'Test Related Accession'
    expect(page).to have_text(title)
    expect(page).to have_css('.token-input-token')
  end
end

When('the user attempts to create an accession without required fields') do
  @accession_data = {}
  @accession_data['title'] = 'Incomplete Accession'

  within '#resource_related_accessions__0__ref__modal' do
    fill_in 'accession_title_', with: @accession_data['title']
    click_on 'Create and Link'
  end
  wait_for_ajax
end

Then('the following error messages are displayed in the modal') do |table|
  within '#resource_related_accessions__0__ref__modal' do
    table.raw.flatten.each do |error_message|
      expect(page).to have_css('.alert.alert-danger', text: /#{Regexp.escape(error_message.split(' - ')[1])}/i)
    end
  end
end

Then('the modal should remain open') do
  expect(page).to have_css('#resource_related_accessions__0__ref__modal', visible: true)
end

When('the user fills in the missing required fields') do
  within '#resource_related_accessions__0__ref__modal' do
    fill_in 'accession_id_0_', with: "ACC_#{Time.now.to_i}"
    fill_in 'accession_accession_date_', with: '2026-01-05'
  end
end

When('the user creates and links a related accession with title {string}') do |title|
  @accession_count ||= 0
  index = @accession_count

  click_on 'Add Related Accession'
  wait_for_ajax

  within "#resource_related_accessions__#{index}__ref__combobox" do
    find('button').click
    click_on 'Create'
  end

  wait_for_ajax

  within "#resource_related_accessions__#{index}__ref__modal" do
    fill_in 'accession_id_0_', with: "ACC_#{Time.now.to_i}_#{index}"
    fill_in 'accession_title_', with: title
    fill_in 'accession_accession_date_', with: '2026-01-05'
    click_on 'Create and Link'
  end

  wait_for_ajax
  @accession_count += 1
end

Then('the resource should have {int} related accessions') do |count|
  related_accessions = all('#resource_related_accessions_ .subrecord-form-list > li')
  expect(related_accessions.length).to eq count
end

Then('the related accessions should be named {string} and {string}') do |first_title, second_title|
  within '#resource_related_accessions__0__ref__combobox' do
    expect(page).to have_text(first_title)
  end

  within '#resource_related_accessions__1__ref__combobox' do
    expect(page).to have_text(second_title)
  end
end

When('the user navigates to edit the resource') do
  visit "#{STAFF_URL}/resources/#{@resource_id}/edit"
  expect(page).to have_content("Resource #{@uuid}")
end

Then('the related accession {string} should be linked') do |title|
  within '#resource_related_accessions__0__ref__combobox' do
    expect(page).to have_text(title)
    expect(page).to have_css('.token-input-token .accession')
  end
end
