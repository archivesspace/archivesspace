# frozen_string_literal: true

require 'spec_helper.rb'
require 'rails_helper.rb'

describe 'Bulk Import', js: true do

  before(:all) do
    @repo = create(:repo, repo_code: "bulk_import_test_#{Time.now.to_i}")
    set_repo(@repo)
    @ead_id = 'VFIRST01'
    @valid_file = File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'bulk_import', 'bulk_import_VFIRST01_test01.csv')
    @invalid_file = File.join(File.dirname(__FILE__), '..', '..', '..', 'backend', 'spec', 'fixtures', 'ead_with_extents.xml')
    @resource = create(:resource, ead_id: @ead_id)
  end

  it 'can create a bulk import (load spreadsheet) job' do
    login_admin
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
    $index.run_index_round
    sleep 5
    visit "/jobs"
    expect(page).to have_text "Load via Spreadsheet"
    first(:link, "View").click
    wait_for_job_to_complete(page)
    visit current_path
    expect(page).to have_link "A subseries"
    expect(page).to have_link "The first series"
  end
end
