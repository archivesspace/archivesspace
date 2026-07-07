# frozen_string_literal: true

Given 'the user is on the Container Labels background job page' do
  click_on 'Create'
  click_on 'Background Job'
  click_on 'Container Labels'
end

Given 'the user fills in and selects the Resource from the Download Container Labels field' do
  fill_in 'token-input-job_source_', with: @uuid
  dropdown_item = find('div.token-input-dropdown li', text: @uuid, wait: 5)
  dropdown_item.click
end

Given 'a Resource with an Archival Object and a Container Instances has been created' do
  visit "#{STAFF_URL}/resources/new"

  fill_in 'resource_title_', with: "Resource #{@uuid}"
  fill_in 'resource_id_0_', with: "Resource #{@uuid}"
  select 'Class', from: 'resource_level_'
  element = find('#resource_lang_materials__0__language_and_script__language_')
  element.send_keys('AU')
  element.send_keys(:tab)

  select 'Single', from: 'resource_dates__0__date_type_'
  within '.input-group.date' do
    fill_in 'resource_dates__0__begin_', with: '2024'
  end

  fill_in 'resource_extents__0__number_', with: '10'
  select 'Cassettes', from: 'resource_extents__0__extent_type_'

  element = find('#resource_finding_aid_language_')
  element.send_keys('ENG')
  element.send_keys(:tab)

  element = find('#resource_finding_aid_script_')
  element.send_keys('Latin')
  element.send_keys(:tab)

  find('button', text: 'Save Resource', match: :first).click

  wait_for_ajax
  expect(page).to have_text "Resource Resource #{@uuid} created"

  url_parts = current_url.split('/')
  url_parts.pop
  @resource_id = url_parts.pop

  click_on 'Add Child'
  wait_for_ajax
  fill_in 'Title', with: "Archival Object 1 #{@uuid}"
  select 'Class', from: 'Level of Description'
  click_on 'Add Container Instance'
  select 'Accession', from: 'archival_object_instances__0__instance_type_'
  find('#archival_object_instances__0__sub_container__top_container__ref__combobox .btn.btn-default.dropdown-toggle').click
  within '#archival_object_instances__0__sub_container__top_container__ref__combobox' do
    click_on 'Create'
  end
  wait_for_ajax
  fill_in 'Indicator', with: "Indicator A #{@uuid}"
  click_on 'Add Location'
  fill_in 'token-input-top_container_container_locations__0__ref_', with: 'test_location'
  dropdown_items = all('li.token-input-dropdown-item2')
  dropdown_items.first.click

  click_on 'Create and Link'

  sleep 3 # ensure created top container is indexed

  click_on 'Save'
  wait_for_ajax
  expect(page).to have_text "Archival Object Archival Object 1 #{@uuid} on Resource Resource #{@uuid} created"
end

Given 'a TSV file is downloaded with the container labels for the resource' do
  files = Dir.glob(File.join(Dir.tmpdir, '*.tsv'))

  downloaded_file = nil
  files.each do |file|
    downloaded_file = file if file.include?('job')
  end

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  expect(load_file).to include("Indicator A #{@uuid}")
end
