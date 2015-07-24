require_relative 'spec_helper'

describe "Jobs" do

  before(:all) do
    backend_login

    @repo = create(:repo, :repo_code => "jobs_test_#{Time.now.to_i}")

    login_to_repo('admin', 'admin', @repo)
  end

  # avoid the dreaded StaleElementReferenceError
  # by starting from the root page each time (?)
  before(:each) do
    $driver.get("#{$frontend}")
  end

  after(:all) do
    logout
  end

  it "can create a find and replace job" do
    resource_title = "#{$$}xxx_resource"
    create_resource({:title => resource_title}, @repo.uri)

    run_index_round

    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Background Jobs").click


    $driver.find_element(:link, "Create Job").click

    $driver.find_element(:id => "job_job_type_").select_option("find_and_replace_job")

    token_input = $driver.find_element(:id,"token-input-find_and_replace_job_ref_")
    token_input.clear
    token_input.click
    token_input.send_keys( resource_title)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click
    $driver.wait_for_ajax

    $driver.find_element(:id => "find_and_replace_job_record_type_").select_option("extent")

    $driver.find_element(:id => "find_and_replace_job_property_").select_option("container_summary")
    $driver.find_element(:id => "find_and_replace_job_find_").send_keys("abc")

    $driver.find_element(:id => "find_and_replace_job_replace_").send_keys("def")

    $driver.find_element(:css => "form#jobfileupload button[type='submit']").click

    expect {
      $driver.find_element_with_text("//h2", /Find and Replace/)
    }.to_not raise_error

  end

  it "can create a print to pdf job" do

    resource_title = "#{$$}xxx_resource_job_test"
    create_resource({:title => resource_title }, @repo.uri )

    run_index_round

    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Background Jobs").click

    $driver.find_element(:link, "Create Job").click

    $driver.find_element(:id => "job_job_type_").select_option("print_to_pdf_job")

    token_input = $driver.find_element(:id,"token-input-print_to_pdf_job_ref_")
    token_input.clear
    token_input.click
    token_input.send_keys( resource_title)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:css => "form#jobfileupload button[type='submit']").click

    expect {
      $driver.find_element_with_text("//h2", /print_to_pdf_job/)
    }.to_not raise_error
  end

end
