# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'csv'
require 'rubyXL/convenience_methods/cell'

describe 'Resources', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    set_repo @repository
    @user = create_user(@repository => ['repository-managers'])
  end

  before(:each) do
    login_user(@user)
    ensure_repository_access
    select_repository(@repository)
  end

  it 'has the generate bulk archival object link included in the more dropdown menu on both the show and edit pages' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")

    run_index_round

    visit "resources/#{resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    wait_for_ajax

    click_on('More')

    using_wait_time(15) do
      within('.dropdown-menu') do
        click_link('Generate Bulk Archival Object Spreadsheet')
      end
    end

    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'More'
    click_on 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'
  end

  it 'successfully generates a bulk archival object spreadsheet for a resource' do
    now = Time.now.to_i

    digital_object = create(:json_digital_object)
    accession = create(:json_accession, title: "Accession Title #{now}")
    location = create(:location, :temporary => generate(:temporary_location_type))
    top_container = create(:json_top_container,
      :container_locations => [
        {
          'ref' => location.uri,
          'status' => 'current',
          'start_date' => generate(:yyyy_mm_dd),
          'end_date' => generate(:yyyy_mm_dd)
        }
      ]
    )

    instances = [
      build(:json_instance_digital, :digital_object => { :ref => digital_object.uri }),
      build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
    ]

    resource = create(:resource, title: "Resource Title #{now}")

    archival_object_1 = create(:json_archival_object,
      :title => "Archival Object Title 1 #{now}",
      :resource => {
        :ref => resource.uri
      },
      :dates => [],
      :notes => [],
      :instances => instances,
      :accession_links => [{'ref' => accession.uri}],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )

    archival_object_2 = create(:json_archival_object,
      :title => "Archival Object Title 2 #{now}",
      :resource => {
        :ref => resource.uri
      },
      :dates => [],
      :notes => [],
      :instances => instances,
      :accession_links => [{'ref' => accession.uri}],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )

    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'More'
    click_on 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      File.delete file if file.include?("bulk_update.resource_")
    end

    # Select only the first archival object
    find('#item1').click

    click_on 'Download Spreadsheet'

    downloaded_spreadsheet_filename = nil
    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      downloaded_spreadsheet_filename = file if file.include?("bulk_update.resource_#{resource.id}")
    end

    expect(downloaded_spreadsheet_filename).to_not be nil

    spreadsheet = RubyXL::Parser.parse(downloaded_spreadsheet_filename)
    sheet = spreadsheet['Updates']
    column_names = sheet[1].cells.map(&:value)

    expect(column_names.length).to eq 166

    id_index = column_names.find_index('id')
    title_index = column_names.find_index('title')

    # First row must contain archival object 1
    expect(sheet[2][id_index].value).to eq archival_object_1.id.to_s
    expect(sheet[2][title_index].value).to eq archival_object_1.title

    # Second row must be empty
    expect(sheet[3]).to eq nil

    column_index = column_names.find_index('related_accessions/0/id_0')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell
    expect(sheet[2][column_index].value).to eq accession.id_0
    column_index = column_names.find_index('related_accessions/0/id_1')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell
    expect(sheet[2][column_index].value).to eq accession.id_1
    column_index = column_names.find_index('related_accessions/0/id_2')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell
    expect(sheet[2][column_index].value).to eq accession.id_2
    column_index = column_names.find_index('related_accessions/0/id_3')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell
    expect(sheet[2][column_index].value).to eq accession.id_3

    column_index = column_names.find_index('instances/0/instance_type')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell

    column_index = column_names.find_index('digital_object/0/digital_object_id')
    expect(sheet[2][column_index]).to be_a RubyXL::Cell
  end

  it 'successfully uploads a bulk archival object spreadsheet and creates a job' do
    login_admin
    select_repository(@repository)

    now = Time.now.to_i

    digital_object = create(:json_digital_object)
    accession = create(:json_accession, title: "Accession Title #{now}")
    location = create(:location, :temporary => generate(:temporary_location_type))
    top_container = create(:json_top_container,
      :container_locations => [
        {
          'ref' => location.uri,
          'status' => 'current',
          'start_date' => generate(:yyyy_mm_dd),
          'end_date' => generate(:yyyy_mm_dd)
        }
      ]
    )

    instances = [
      build(:json_instance_digital, :digital_object => { :ref => digital_object.uri }),
      build(:json_instance, :sub_container => build(:json_sub_container, :top_container => { :ref => top_container.uri }))
    ]

    resource = create(:resource, title: "Resource Title #{now}")

    archival_object_1 = create(:json_archival_object,
      :title => "Archival Object Title 1 #{now}",
      :resource => {
        :ref => resource.uri
      },
      :dates => [],
      :notes => [],
      :instances => instances,
      :accession_links => [{'ref' => accession.uri}],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )

    archival_object_2 = create(:json_archival_object,
      :title => "Archival Object Title 2 #{now}",
      :resource => {
        :ref => resource.uri
      },
      :dates => [],
      :notes => [],
      :instances => instances,
      :accession_links => [{'ref' => accession.uri}],
      :subjects => [],
      :linked_agents => [],
      :rights_statements => [],
      :external_documents => [],
      :extents => [],
      :lang_materials => []
    )

    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'More'
    click_on 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      File.delete file if file.include?("bulk_update.resource_")
    end

    # Select only the first archival object
    find('#item1').click
    find('#item2').click

    click_on 'Download Spreadsheet'

    downloaded_spreadsheet_filename = nil
    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      downloaded_spreadsheet_filename = file if file.include?("bulk_update.resource_#{resource.id}")
    end

    expect(downloaded_spreadsheet_filename).to_not be nil

    # Modify spreadsheet to upload
    spreadsheet = RubyXL::Parser.parse(downloaded_spreadsheet_filename)
    sheet = spreadsheet['Updates']
    column_names = sheet[1].cells.map(&:value)

    expect(column_names.length).to eq 166

    title_index = column_names.find_index('title')
    sheet[2][title_index].change_contents("Updated Archival Object Title 1 #{now}")
    sheet[3][title_index].change_contents("Updated Archival Object Title 2 #{now}")

    # Save excel file after updates
    spreadsheet.write(downloaded_spreadsheet_filename)

    click_on 'Done'

    click_on 'Create'
    click_on 'Background Job'
    click_on 'Bulk Archival Object Updater'

    expect(page).to have_button('Start Job', disabled: true)

    attach_file(
      'job_file_input',
      downloaded_spreadsheet_filename,
      make_visible: true
    )

    click_on 'Start Job'

    expect(page).to have_text 'Spreadsheet Bulk Archival Object Updater Job'

    job_status = ''
    while job_status != 'completed'
      sleep 5
      visit current_url

      element = find('#job_status')
      job_status = element['data-current-status']
    end

    elements = all('#jobRecordsSpool .subrecord-form-fields a')
    expect(elements.length).to eq 2

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    element = find('#tree-container')
    expect(element).to have_text "Updated Archival Object Title 1 #{now}"
    expect(element).to have_text "Updated Archival Object Title 2 #{now}"
  end

  it 'can duplicate a resource from another resource with all the archival objects' do
    login_admin
    select_repository(@repository)

    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_objects = (0...10).map do |index|
      create(
        :archival_object,
        title: "Archival Object Title #{index} #{now}",
        resource: { 'ref' => resource.uri }
      )
    end

    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Duplicate Resource'
    within '#confirmChangesModal' do
      click_on 'Duplicate Resource'
    end

    expect(page).to have_selector('h2', visible: true, text: 'resource_duplicate_job')

    job_status = ''
    while job_status != 'completed'
      sleep 5
      visit current_url

      element = find('#job_status')
      job_status = element['data-current-status']
    end

    element = find('.job-status.form-group')
    expect(element).to have_text 'Status'
    expect(element).to have_text 'Completed'

    element = find('#generated_uris')
    expect(element).to have_text 'New & Modified Records'

    links = all('#jobRecordsSpool .subrecord-form-fields a')
    expect(links.length).to eq 1
    expect(links[0].text).to eq "[Duplicated] #{resource.title}"

    click_on "[Duplicated] #{resource.title}"

    click_on 'Edit'

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "[Duplicated] #{resource.title} Resource")
    end

    expect(find('#resource_title_').value).to eq "[Duplicated] #{resource.title}"
    expect(find('#resource_id_0_').value).to eq "[Duplicated] #{resource.id_0}"
    expect(find('#resource_id_1_').value).to eq "#{resource.id_1}"
    expect(find('#resource_id_2_').value).to eq "#{resource.id_2}"
    expect(find('#resource_id_3_').value).to eq "#{resource.id_3}"

    # Archival Objects
    elements = all('.largetree-node')
    expect(elements.length).to eq 10
  end

  it 'can spawn a resource from an existing accession' do
    now = Time.now.to_i
    accession = create(:accession, title: "Accession Title #{now}", condition_description: 'condition_description')
    run_index_round

    visit "accessions/#{accession.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{accession.title} Accession")
    end

    click_on 'Spawn'
    click_on 'Resource'

    expect(page).to have_text "A new Resource has been spawned from Accession Accession Title #{now}. This record is unsaved. You must click Save for the record to be created in the system."

    fill_in 'resource_id_0_', with: '1'
    fill_in 'resource_id_1_', with: '2'
    fill_in 'resource_id_2_', with: '3'
    fill_in 'resource_id_3_', with: '4'

    select 'Collection', from: 'Level of Description'

    expect(page).to have_css('#resource_lang_materials__0__language_and_script__language_.initialised')

    element = find('#resource_finding_aid_language_')
    element.click
    element.send_keys('ENG')
    element.send_keys(:tab)

    element = find('#resource_finding_aid_script_')
    element.click
    element.send_keys('Latin')
    element.send_keys(:tab)

    # no collection management
    expect(page).to_not have_css("#resource_collection_management__cataloged_note_")

    # condition and content descriptions have come across as notes fields
    notes_toggle = all('#resource_notes_ .collapse-subrecord-toggle')
    notes_toggle[0].click

    page.execute_script("$('#resource_notes__0__subnotes__0__content_').data('CodeMirror').toTextArea()")
    element = find('#resource_notes__0__subnotes__0__content_.initialised', visible: false)
    expect(element.value).to eq(accession.content_description)

    notes_toggle[1].click

    using_wait_time(15) do
      expect(page).to have_selector('#resource_notes__1__content__0_', text: accession.condition_description)
    end

    select 'Single', from: 'resource_dates__0__date_type_'
    fill_in 'resource_dates__0__begin_', with: '1978'
    fill_in 'resource_extents__0__number_', with: '10'
    select 'Cassettes', from: 'resource_extents__0__extent_type_'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{accession.title} created"

    expect(find('#resource_dates__0__date_type_').value).to eq('single')
    expect(find('#resource_dates__0__begin_').value).to eq('1978')
    expect(find('#resource_extents__0__number_').value).to eq('10')
    expect(find('#resource_extents__0__extent_type_').value).to eq('cassettes')
  end

  it 'reports errors and warnings when creating an invalid Resource' do
    click_on 'Create'
    click_on 'Resource'

    element = find('#resource_title_')
    element.fill_in with: ''

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    within '#form_messages' do
      messages = [
        'Number - Property is required but was missing',
        'Type - Property is required but was missing',
        'Title - Property is required but was missing',
        'Identifier - Property is required but was missing',
        'Level of Description - Property is required but was missing',
        'Language of Description - Property is required but was missing',
        'Script of Description - Property is required but was missing'
      ]

      element = find('.alert.alert-danger.with-hide-alert')
      messages.each do |message|
        expect(element).to have_text message
      end
    end

    expect(page).to have_css '.identifier-fields.has-error'
  end

  it 'prepopulates the top container modal with search for current resource when linking on the resource edit page' do
    # Create top containers
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    location = create(:location)
    container_location = build(:container_location, ref: location.uri)
    container = create(:top_container, indicator: "Container #{now}", container_locations: [container_location])
    run_all_indexers

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Container Instance'

    select 'Text', from: 'resource_instances__0__instance_type_'
    element = find('#resource_instances__0__container_')
    within element do
      find('button.dropdown-toggle[aria-label="Link to top container"]').click
      click_on 'Browse'
    end

    within '#resource_instances__0__sub_container__top_container__ref__modal' do
      expect(page).to have_text 'Browse Top Containers'
      element = find("#_repositories_#{@repository.id}_resources_#{resource.id}")
      expect(element).to have_text resource.title
      expect(element).to have_css '.token-input-delete-token'

      wait_for_ajax

      find('.token-input-delete-token').click
      fill_in 'Keyword', with: '*'
      click_on 'Search'

      wait_for_ajax

      using_wait_time(15) do
        expect(page).to have_xpath("//tr[contains(., '#{container.indicator}')]")
      end

      within(:xpath, "//tr[contains(., '#{container.indicator}')]") do
        find('input').click
      end

      click_on 'Link'
    end

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    run_index_round

    expect(page).to have_text "Resource #{resource.title} updated"

    run_periodic_index

    within '#resource_instances__0__container_' do
      find('[aria-label="Link to top container"]').click
      click_on 'Browse'
    end

    within '#resource_instances__0__sub_container__top_container__ref__modal' do
      elements = all('tr')
      expect(elements.length).to eq(2)
    end
  end

  it 'can add a rights statement with linked agent to a Resource' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Rights Statement'

    wait_for_ajax

    select 'Copyright', from: 'resource_rights_statements__0__rights_type_'
    select 'Copyrighted', from: 'resource_rights_statements__0__status_'
    fill_in 'resource_rights_statements__0__start_date_', with: '2012-01-01'

    element = find('#resource_rights_statements__0__jurisdiction_')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)

    within '#resource_rights_statements_' do
      click_on 'Add Agent Link'
    end

    element = find('#token-input-resource_rights_statements__0__linked_agents__0__ref_')
    element.fill_in with: 'resources'
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{resource.title} updated"

    run_index_round

    find_link(resource.title, match: :first).click

    expect(page).to have_css '#resource_rights_statements_'
    find('#resource_rights_statements_ .accordion-toggle').click
    expect(page).to have_css '#rights_statement_0'
    expect(page).to have_css '#rights_statement_0_linked_agents'
  end

  it 'can create a resource' do
    now = Time.now.to_i

    click_on 'Create'
    click_on 'Resource'
    fill_in 'resource_title_', with: "Resource Title #{now}"
    fill_in 'resource_id_0_', with: "1 #{now}"
    fill_in 'resource_id_1_', with: "2 #{now}"
    fill_in 'resource_id_2_', with: "3 #{now}"
    fill_in 'resource_id_3_', with: "4 #{now}"

    element = find('#resource_lang_materials__0__language_and_script__language_')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)

    element = find('#resource_finding_aid_language_')
    element.click
    element.send_keys('ENG')
    element.send_keys(:tab)

    element = find('#resource_finding_aid_script_')
    element.click
    element.send_keys('Latin')
    element.send_keys(:tab)

    select 'Single', from: 'resource_dates__0__date_type_'
    fill_in 'resource_dates__0__begin_', with: '1978'
    select 'Collection', from: 'resource_level_'
    fill_in 'resource_extents__0__number_', with: '10'
    select 'Cassettes', from: 'resource_extents__0__extent_type_'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource Resource Title #{now} created"

    element = find('#tree-container')
    expect(element).to have_text "Resource Title #{now}"
  end

  it 'reports warnings when updating a Resource with invalid data' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    fill_in 'resource_title_', with: ''

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    within '#form_messages' do
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element).to have_text 'Title - Property is required but was missing'
    end
  end

  it 'reports errors if adding an empty child to a Resource' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Child'

    # Click on save (+1)
    find('#createPlusOne').click

    within '#form_messages' do
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element).to have_text 'Level of Description - Property is required but was missing'
    end
  end

  it 'reports error if title is empty and no date is provided' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Child'

    select 'Item', from: 'archival_object_level_'

    # Click on save (+1)
    find('#createPlusOne').click

    within '#form_messages' do
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element).to have_text 'Dates - one or more required (or enter a Title)'
      expect(element).to have_text 'Title - must not be an empty string (or enter a Date)'
    end
  end

  it 'can edit a Resource, add a second Extent, then remove it' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round
    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Extent'

    fill_in 'resource_extents__1__number_', with: '5'
    select 'Volumes', from: 'resource_extents__1__extent_type_'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{resource.title} updated"

    click_on 'Close Record'

    elements = all('#resource_extents_ .panel-heading')
    expect(elements.length).to eq 2

    click_on 'Edit'

    elements = all('#resource_extents_ .subrecord-form-remove')
    expect(elements.length).to eq 2

    elements[1].click
    click_on 'Confirm Removal'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    click_on 'Close Record'

    elements = all('#resource_extents_ .panel-heading')
    expect(elements.length).to eq 1
  end

  it 'has the Include URIs checkbox checked by default inside the EAD Export dropdown menu' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    within '#form_download_ead', visible: false do
      element = find('#include-uris', visible: false)
      expect(element.checked?).to eq true
    end
  end

  it 'exports and downloads the resource to xml' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    files = Dir.glob(File.join(Dir.tmpdir, '*_ead.xml'))
    files.each do |file|
      File.delete file
    end

    click_on 'Export'

    using_wait_time(15) do
      within('.dropdown-menu') do
        click_link('Download EAD')
      end
    end

    files = Dir.glob(File.join(Dir.tmpdir, '*_ead.xml'))
    expect(files.length).to eq 1
    file = File.read(files[0])
    expect(file).to include(resource.title)
  end

  it 'exports a prefilled CSV template to import digital objects to archival objects' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_objects = create_list(:archival_object, 10, title: "Archival Object Title #{now}", :resource => { ref: resource.uri })
    run_index_round

    visit "resources/#{resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    files.each do |file|
      File.delete file
    end

    click_on 'Export'
    click_on 'Download Digital Object Template'

    files = Dir.glob(File.join(Dir.tmpdir, '*.csv'))
    expect(files.length).to eq 1
    file = File.read(files[0])
    csv_generated = CSV.parse(file)

    # Load original CSV template
    csv_template_path = File.join(ASUtils.find_base_directory, 'templates', 'bulk_import_DO_template.csv')
    csv_template = CSV.read(csv_template_path)
    csv_template_columns = csv_template[0]
    csv_template_column_explanations = csv_template[1]

    expect(csv_template_columns).to eq csv_generated[1]
    expect(csv_template_column_explanations).to eq csv_generated[2]

    for x in 0..(archival_objects.length - 1)
      expect(csv_generated[x + 3]).to include resource.uri
      expect(csv_generated[x + 3]).to include archival_objects[x].uri
    end
  end

  it 'closes the export dropdown menu after Download EAD and Download MARCXML are clicked' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    expect(page).to have_css '#export-dropdown-toggle + .dropdown-menu', visible: false
    click_on 'Export'
    expect(page).to have_css '#export-dropdown-toggle + .dropdown-menu', visible: true
    click_on 'Download EAD'
    expect(page).to have_css '#export-dropdown-toggle + .dropdown-menu', visible: false
    click_on 'Export'
    expect(page).to have_css '#export-dropdown-toggle + .dropdown-menu', visible: true
    click_on 'Download MARCXML'
    expect(page).to have_css '#export-dropdown-toggle + .dropdown-menu', visible: false
  end

  it 'can apply and remove filters when browsing for linked agents in the linker modal' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    person = create(:agent_person)
    agent_corporate_entity = create(:agent_corporate_entity)
    run_index_round

    visit "resources/#{resource.id}/edit"
    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Agent Links'
    click_on 'Add Agent Link'

    find('#resource_linked_agents_ .linker-wrapper .dropdown-toggle').click
    find('#resource_linked_agents_ #dropdownMenuAgents .linker-browse-btn').click

    element = find('.linker-container')
    expect(element).to have_text 'Filter by text'

    click_on 'Corporate Entity'
    element = find('.linker-container')
    expect(element).to have_text 'Filtered By'
    expect(page).to have_css '.linker-container .glyphicon-remove'
    find('.linker-container .glyphicon-remove').click
    expect(page).to_not have_css '.linker-container .glyphicon-remove'
  end

  it 'adds the result for calculate extent to the correct subrecord' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round
    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Deaccession'

    select 'Deaccession', from: 'resource_deaccessions__0__date__label_'
    fill_in 'resource_deaccessions__0__description_', with: "Deaccession description #{now}"
    select 'Single', from: 'resource_deaccessions__0__date__date_type_'
    fill_in 'resource_deaccessions__0__date__begin_', with: '2012-05-14'

    within '#resource_deaccessions_' do
      click_on 'Add Extent'
    end

    fill_in 'resource_deaccessions__0__extents__0__number_', with: '4'

    select 'Cassettes', from: 'resource_deaccessions__0__extents__0__extent_type_'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    expect(page).to have_text "Resource Resource Title #{now} updated"

    find('#other-dropdown').click
    click_on 'Calculate Extent'

    within '#extentCalculationModal' do
      within '#form_extent' do
        select 'Whole', from: 'extent_portion_'
        fill_in 'extent_number_', with: '1'
        select 'Cassettes', from: 'extent_extent_type_'
      end

      click_on 'Create Extent'
    end

    element = find('#resource_extents_')
    expect(element).to have_css('li[data-index="1"]')
  end

  it 'enforces required fields in extent calculator' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round
    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    find('#other-dropdown').click
    click_on 'Calculate Extent'

    within '#extentCalculationModal' do
      fill_in 'extent_number_', with: ''

      click_on 'Create Extent'
      expect(page.driver.browser.switch_to.alert.text).to eq 'Please ensure that all required fields contain a value.'
    end
  end

  it 'can create a new digital object instance with a note to a resource' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round

    visit "resources/#{resource.id}/edit"

    using_wait_time(15) do
      expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")
    end

    click_on 'Add Digital Object'

    element = find("div[data-id-path='resource_instances__0__digital_object_']")
    within element do
      find('.dropdown-toggle').click
      click_on 'Create'
    end

    element = find('#resource_instances__0__digital_object__ref__modal')
    within element do
      fill_in 'Title', with: "Digital Object Title #{now}"
      fill_in 'Identifier', with: "Digital Object Identifier #{now}"

      click_on 'Add Note'

      select_element = find('select.top-level-note-type')
      select_element.select 'Summary'

      fill_in 'digital_object_notes__0__label_', with: 'Summary Label'

      page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').setValue('Summary content')")
      page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').save()")
      page.execute_script("$('#digital_object_notes__0__content__0_').data('CodeMirror').toTextArea()")
      textarea = find('#digital_object_notes__0__content__0_')
      expect(textarea.value).to eq('Summary content')

      click_on 'Create and Link'
    end

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{resource.title} updated"

    element = find('.token-input-token .digital_object')
    expect(element).to have_text "Digital Object Title #{now}"
  end
end
