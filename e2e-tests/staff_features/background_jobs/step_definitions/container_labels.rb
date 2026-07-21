# frozen_string_literal: true

Given 'a Container Instance for the Archival Object has been created' do
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
  all('li.token-input-dropdown-item2').first.click

  click_on 'Create and Link'

  sleep 3 # ensure created top container is indexed

  click_on 'Save'
  wait_for_ajax
  expect(page).to have_text "Archival Object Archival Object #{@uuid} updated"
end

Then 'a TSV file is downloaded with the container labels for the resource' do
  downloaded_file = Dir.glob(File.join(Dir.tmpdir, '*.tsv'))
                       .select { |file| File.basename(file).include?('job') }
                       .max_by { |file| File.mtime(file) }

  expect(downloaded_file).to_not eq nil

  load_file = File.read(downloaded_file)
  FileUtils.rm_f(downloaded_file)
  expect(load_file).to include("Indicator A #{@uuid}")
end
