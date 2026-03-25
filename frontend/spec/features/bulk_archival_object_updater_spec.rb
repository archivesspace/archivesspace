# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'
require 'rubyXL/convenience_methods/cell'

describe 'Bulk Archival Object Updater', js: true do
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

    visit "resources/#{resource.id}"

    expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")

    wait_for_ajax

    find('#other-dropdown button').click

    within('.dropdown-menu') do
      click_link('Generate Bulk Archival Object Spreadsheet')
    end

    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    visit "resources/#{resource.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")

    find('#other-dropdown button').click

    within('.dropdown-menu') do
      click_link('Generate Bulk Archival Object Spreadsheet')
    end
    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'
  end

  it 'successfully generates a bulk archival object spreadsheet for a resource' do
    now = Time.now.to_i

    digital_object = create(:json_digital_object)
    accession = create(:json_accession, title: "Accession Title #{now}")
    location = create(:location, temporary: generate(:temporary_location_type))
    top_container = create(:json_top_container,
                           container_locations: [
                             {
                               'ref' => location.uri,
                               'status' => 'current',
                               'start_date' => generate(:yyyy_mm_dd),
                               'end_date' => generate(:yyyy_mm_dd)
                             }
                           ])

    instances = [
      build(:json_instance_digital, digital_object: { ref: digital_object.uri }),
      build(:json_instance,
            sub_container: build(:json_sub_container, top_container: { ref: top_container.uri }))
    ]

    resource = create(:resource, title: "Resource Title #{now}")

    archival_object_1 = create(:json_archival_object,
                               title: "Archival Object Title 1 #{now}",
                               resource: {
                                 ref: resource.uri
                               },
                               dates: [],
                               notes: [],
                               instances:,
                               accession_links: [{ 'ref' => accession.uri }],
                               subjects: [],
                               linked_agents: [],
                               rights_statements: [],
                               external_documents: [],
                               extents: [],
                               lang_materials: [])

    create(:json_archival_object,
           title: "Archival Object Title 2 #{now}",
           resource: {
             ref: resource.uri
           },
           dates: [],
           notes: [],
           instances:,
           accession_links: [{ 'ref' => accession.uri }],
           subjects: [],
           linked_agents: [],
           rights_statements: [],
           external_documents: [],
           extents: [],
           lang_materials: [])

    visit "resources/#{resource.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")

    click_on 'More'

    within('.dropdown-menu') do
      click_link('Generate Bulk Archival Object Spreadsheet')
    end

    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      File.delete file if file.include?('bulk_update.resource_')
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
    location = create(:location, temporary: generate(:temporary_location_type))
    top_container = create(:json_top_container,
                           container_locations: [
                             {
                               'ref' => location.uri,
                               'status' => 'current',
                               'start_date' => generate(:yyyy_mm_dd),
                               'end_date' => generate(:yyyy_mm_dd)
                             }
                           ])

    instances = [
      build(:json_instance_digital, digital_object: { ref: digital_object.uri }),
      build(:json_instance,
            sub_container: build(:json_sub_container, top_container: { ref: top_container.uri }))
    ]

    resource = create(:resource, title: "Resource Title #{now}")

    create(:json_archival_object,
           title: "Archival Object Title 1 #{now}",
           resource: {
             ref: resource.uri
           },
           dates: [],
           notes: [],
           instances:,
           accession_links: [{ 'ref' => accession.uri }],
           subjects: [],
           linked_agents: [],
           rights_statements: [],
           external_documents: [],
           extents: [],
           lang_materials: [])

    create(:json_archival_object,
           title: "Archival Object Title 2 #{now}",
           resource: {
             ref: resource.uri
           },
           dates: [],
           notes: [],
           instances:,
           accession_links: [{ 'ref' => accession.uri }],
           subjects: [],
           linked_agents: [],
           rights_statements: [],
           external_documents: [],
           extents: [],
           lang_materials: [])

    visit "resources/#{resource.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")

    wait_for_ajax

    click_on 'More'

    within('.dropdown-menu') do
      click_link('Generate Bulk Archival Object Spreadsheet')
    end

    expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
    expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
    expect(page).to have_text 'Selected Records: 0'

    files = Dir.glob(File.join(Dir.tmpdir, '*.xlsx'))
    files.each do |file|
      File.delete file if file.include?('bulk_update.resource_')
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

    expect(page).to have_selector('h2', visible: true, text: "#{resource.title} Resource")

    element = find('#tree-container')
    expect(element).to have_text "Updated Archival Object Title 1 #{now}"
    expect(element).to have_text "Updated Archival Object Title 2 #{now}"
  end

  context 'when bulk_archival_object_updater_max_rows is overridden to 2' do
    before(:each) do
      execute_script("window.localStorage.setItem('APPCONFIG_MAX_ROWS', '2');")

      override = page.evaluate_script("window.localStorage.getItem('APPCONFIG_MAX_ROWS');")
      expect(override).to eq('2')
    end

    after(:each) do
      execute_script("window.localStorage.removeItem('APPCONFIG_MAX_ROWS');")

      override = page.evaluate_script("window.localStorage.getItem('APPCONFIG_MAX_ROWS');")
      expect(override).to be_nil
    end

    it 'shows a warning when 6 records are selected' do
      now = Time.now.to_i

      resource = create(:resource, title: "Resource Title #{now}")

      5.times do |i|
        create(:json_archival_object,
               title: "Archival Object Title #{i} #{now}",
               resource: {
                 ref: resource.uri
               })
      end

      visit "/bulk_archival_object_updater/download?resource=%2Frepositories%2F#{@repository.id}%2Fresources%2F#{resource.id}"

      expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
      expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
      expect(page).to have_text 'Selected Records: 0'

      # Select all the archival objects
      find('#item0').click

      expect(page).to have_text 'Selected Records: 6'
      expect(page).to have_text 'Warning: The number of rows that will be generated in this spreadsheet exceeds'
    end

    it 'does not show a warning when 1 record is selected' do
      now = Time.now.to_i

      resource = create(:resource, title: "Resource Title #{now}")

      5.times do |i|
        create(:json_archival_object,
               title: "Archival Object Title #{i} #{now}",
               resource: {
                 ref: resource.uri
               })
      end

      visit "/bulk_archival_object_updater/download?resource=%2Frepositories%2F#{@repository.id}%2Fresources%2F#{resource.id}"

      expect(page).to have_text 'Generate Bulk Archival Object Spreadsheet'
      expect(page).to have_text 'Use the form below to select the Archival Objects you wish to bulk update.'
      expect(page).to have_text 'Selected Records: 0'

      # Select only the first archival object
      find('#item1').click

      expect(page).to have_text 'Selected Records: 1'
      expect(page).not_to have_text 'Warning: The number of rows that will be generated in this spreadsheet exceeds'
    end
  end
end
