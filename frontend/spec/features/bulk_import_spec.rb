# frozen_string_literal: true

require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Bulk Import', js: true do
  let(:admin) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before(:all) do
    @repo = create(:repo, repo_code: "bulk_import_test_#{Time.now.to_i}")
    set_repo(@repo)
    @ead_id = 'VFIRST01'
    @valid_file = File.expand_path(
        File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'bulk_import', 'bulk_import_VFIRST01_test01.csv'))
    @valid_file_with_conditions_governing_access_notes = File.expand_path(
        File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'bulk_import', 'bulk_import_VFIRST01_with_conditions_governing_access_notes.xlsx'))
    @invalid_file = File.expand_path(
        File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'ead_with_extents.xml'))
    @resource = create(:resource, ead_id: @ead_id)
  end

  it 'can create a bulk import (load spreadsheet) job' do
    login_user(admin)
    select_repository(@repo)

    edit_resource(@resource)
    page.has_css? "form#resource_form"
    within "form#resource_form" do
      page.has_css? "#resource_ead_id_"
      expect(find(id: "resource_ead_id_").value).to eq @ead_id
    end
    click_link "Load via Spreadsheet"
    expect(find(id: "bulkFileButton").disabled?).to be true
    page.execute_script("return $('#excel_file')[0]").send_keys(@invalid_file)
    page.driver.browser.switch_to.alert.accept
    expect(find(id: "bulkFileButton").disabled?).to be true
    page.execute_script("return $('#excel_file')[0]").send_keys(@valid_file)
    expect(find(id: "bulkFileButton").disabled?).to be false
    find(id: "bulkFileButton").click
    sleep 5
    run_indexer
    sleep 5
    visit "/jobs"
    expect(page).to have_text "Load via Spreadsheet"
    first(:link, "View").click
    wait_for_job_to_complete(page)
    visit current_path
    expect(page).to have_link "A subseries"
    expect(page).to have_link "The first series"
  end

  it 'creates archival objects with conditions governing access notes and sets the local access restriction type when no dates provided' do
    login_user(admin)
    select_repository(@repo)

    edit_resource(@resource)
    page.has_css? "form#resource_form"
    within "form#resource_form" do
      page.has_css? "#resource_ead_id_"
      expect(find(id: "resource_ead_id_").value).to eq @ead_id
    end

    click_link "Load via Spreadsheet"
    expect(find(id: "bulkFileButton").disabled?).to be true
    page.execute_script("return $('#excel_file')[0]").send_keys(@valid_file_with_conditions_governing_access_notes)
    expect(find(id: "bulkFileButton").disabled?).to be false
    find(id: "bulkFileButton").click
    sleep 5
    run_indexer
    sleep 5

    visit "/jobs"
    expect(page).to have_text "Load via Spreadsheet"
    first(:link, "View").click
    wait_for_job_to_complete(page)
    visit current_path
    expect(page).to have_link 'Closed due to personnel records'
    click_on 'Closed due to personnel records'

    windows[1].close

    click_on 'Edit'

    wait_for_ajax

    within '#notes' do
      click_on 'Expand'
    end

    element = find('#archival_object_notes__0__type_')
    expect(element.value).to eq 'accessrestrict'

    element = find('#archival_object_notes__0__rights_restriction__local_access_restriction_type_')
    expect(element.value).to eq ["closed_personnel_records"]

    element = find('#archival_object_notes__0__rights_restriction__begin_')
    expect(element.value).to eq ''

    element = find('#archival_object_notes__0__rights_restriction__end_')
    expect(element.value).to eq ''
  end
end
