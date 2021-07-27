# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Bulk Import' do
  before(:all) do
    @repo = create(:repo, repo_code: "bulk_import_test_#{Time.now.to_i}")
    set_repo(@repo)
    @ead_id = 'VFIRST01'
    @valid_file = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'backend', 'spec', 'fixtures', 'bulk_import', 'bulk_import_VFIRST01_test01.csv')
    @invalid_file = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'backend', 'spec', 'fixtures', 'ead_with_extents.xml')
    @resource = create(:resource, ead_id: @ead_id)
    @driver = Driver.get.login_to_repo($admin, @repo)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can create a bulk import (load spreadsheet) job' do
    @driver.get_edit_page(@resource)

    # ensure the resource has the expected ead_id for the fixture file
    expect(@driver.find_element(id: 'resource_ead_id_').attribute('value')).to match(/#{@ead_id}/)
    @driver.find_element(:link, 'Load via Spreadsheet').click
    submit_button = @driver.find_element(id: 'bulkFileButton')

    # the submit button should be disabled by default
    expect(submit_button.attribute('disabled')).not_to be_nil

    # and should remain disabled if an invalid file type is selected
    @driver.execute_script("return $('#excel_file')[0]").send_keys(@invalid_file)
    begin
      @driver.switch_to.alert.accept
    rescue Selenium::WebDriver::Error::NoAlertOpenError
      retry
    end
    expect(submit_button.attribute('disabled')).not_to be_nil

    # the submit button should become available with a valid file type
    @driver.execute_script("return $('#excel_file')[0]").send_keys(@valid_file)
    expect(submit_button.attribute('disabled')).to be_nil
    # submit the job, then we can close the modal
    submit_button.click
    @driver.find_element(class: 'btn-cancel').click

    # and we can view the job in background jobs
    run_index_round
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Background Jobs')
    expect do
      @driver.find_element_with_text('//td', /Load via Spreadsheet/)
    end.not_to raise_error

    # access the job page and confirm new records were created
    @driver.find_element(:link, 'View').click
    assert(5) { @driver.click_and_wait_until_gone(css: 'button.btn-refresh') }
    expect do
      @driver.find_element_with_text('//a', /A subseries/)
      @driver.find_element_with_text('//a', /The first series/)
    end.not_to raise_error
  end
end
