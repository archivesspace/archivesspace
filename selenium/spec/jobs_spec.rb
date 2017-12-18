require_relative 'spec_helper'

describe "Jobs" do

  before(:all) do
    @repo = create(:repo, :repo_code => "jobs_test_#{Time.now.to_i}")
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
    @driver.quit
  end

  it "can create a find and replace job" do

    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, "Background Jobs").click


    @driver.find_element(:link, "Create Job").click
    @driver.click_and_wait_until_gone(:link, 'Batch Find and Replace (Beta)')

    token_input = @driver.find_element(:id,"token-input-find_and_replace_job_ref_")
    @driver.typeahead_and_select( token_input, @resource1.title )

    @driver.find_element(:id => "find_and_replace_job_record_type_").select_option("extent")

    @driver.find_element(:id => "find_and_replace_job_property_").select_option("container_summary")
    @driver.find_element(:id => "find_and_replace_job_find_").send_keys("abc")

    @driver.find_element(:id => "find_and_replace_job_replace_").send_keys("def")

    @driver.find_element(:css => "form#jobfileupload button[type='submit']").click

    expect {
      @driver.find_element_with_text("//h2", /Find and Replace/)
    }.to_not raise_error

  end

  it "can create a print to pdf job" do

    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, "Background Jobs").click

    @driver.find_element(:link, "Create Job").click
    @driver.click_and_wait_until_gone(:link, 'Print To PDF')

    token_input = @driver.find_element(:id,"token-input-print_to_pdf_job_ref_")
    @driver.typeahead_and_select( token_input, @resource2.title ) 

    @driver.find_element(:css => "form#jobfileupload button[type='submit']").click

    expect {
      @driver.find_element_with_text("//h2", /print_to_pdf_job/)
    }.to_not raise_error
  end

  it "can create a report job" do
    run_index_round

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, "Background Jobs")

    @driver.find_element(:link, "Create Job").click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, 'Reports')

    @driver.find_element(:xpath => "//button[@data-report = 'accession_report']").click

    # wait for the slow fade to finish and all sibling items to be removed
    sleep(2)

    job_type = @driver.execute_script("return $('#report_job_jsonmodel_type_').val()")
    expect(job_type).to eq('report_job')

    report_type = @driver.execute_script("return $('#report_type_').val()")
    expect(report_type).to eq('accession_report')

    @driver.find_element(:id => "report_job_format").select_option("csv")
    @driver.click_and_wait_until_element_gone(@driver.find_element_with_text("//button", /Queue Job/))

    @driver.find_element_with_text("//h2", /report_job/)
  end

end
