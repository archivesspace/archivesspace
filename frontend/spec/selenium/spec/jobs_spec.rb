# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Jobs' do
  before(:all) do
    @repo = create(:repo, repo_code: "jobs_test_#{Time.now.to_i}")
    set_repo(@repo)

    @resource1 = create(:resource)
    @resource2 = create(:resource)

    @driver = Driver.get.login_to_repo($admin, @repo)
  end

  # avoid the dreaded StaleElementReferenceError
  # by starting from the root page each time (?)
  before(:each) do
    @driver.go_home
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can create a find and replace job' do
    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Background Jobs').click

    @driver.find_element(:link, 'Create Job').click
    @driver.click_and_wait_until_gone(:link, 'Batch Find and Replace (Beta)')

    token_input = @driver.find_element(:id, 'token-input-job_ref_')
    @driver.typeahead_and_select(token_input, @resource1.title)

    @driver.find_element(id: 'job_record_type_').select_option('extent')

    @driver.find_element(id: 'job_property_').select_option('container_summary')
    @driver.find_element(id: 'job_find_').send_keys('abc')

    @driver.find_element(id: 'job_replace_').send_keys('def')

    @driver.find_element(css: "form#job_form button[type='submit']").click

    expect do
      @driver.find_element_with_text('//h2', /Find and Replace/)
    end.not_to raise_error
  end

  it 'can create a print to pdf job' do
    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Background Jobs').click

    @driver.find_element(:link, 'Create Job').click
    @driver.click_and_wait_until_gone(:link, 'Generate PDF')

    token_input = @driver.find_element(:id, 'token-input-job_source_')
    @driver.typeahead_and_select(token_input, @resource2.title)

    @driver.click_and_wait_until_gone(:css, "form#job_form button[type='submit']")

    expect do
      @driver.find_element_with_text('//h2', /print_to_pdf_job/)
    end.not_to raise_error
  end

  it 'can create a report job' do
    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Background Jobs')

    @driver.find_element(:link, 'Create Job').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Create Report')

    @driver.find_element(css: ".select-report[for = 'accession_report']").click

    # wait for the slow fade to finish and all sibling items to be removed
    sleep(2)

    job_type = @driver.execute_script("return $('#job_jsonmodel_type_').val()")
    expect(job_type).to eq('report_job')

    report_type = @driver.execute_script("return $('#job_report_type_').val()")
    expect(report_type).to eq('accession_report')

    @driver.find_element(id: 'job_format_').select_option('csv')
    @driver.find_element(css: "form#job_form button[type='submit']").click

    expect do
      @driver.find_element_with_text('//h2', /report_job/)
    end.not_to raise_error
  end

  it 'can show a list of background jobs' do
    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Background Jobs')
    expect do
      @driver.find_element_with_text('//td', /Accession Report/)
      @driver.find_element_with_text('//td', /Generate PDF/)
      @driver.find_element_with_text('//td', /Batch Find and Replace/)
    end.not_to raise_error
  end
end
