require_relative 'spec_helper'

describe "Resources Form" do

  before(:all) do
    @repo = create(:repo, :repo_code => "resources_test_#{Time.now.to_i}")

    create_subjects
    set_repo @repo
    run_all_indexers


    @viewer_user = create_user(@repo => ['repository-viewers'])

    @driver = Driver.get
    @driver.login_to_repo($admin, @repo)
  end

  before(:each) do
    @r = create(:resource)

    @driver.get_edit_page(@r)
    @driver.wait_for_ajax
  end


  after(:all) do
    @driver.quit
  end


  it "displays icons for the different subject types" do
    # click on Add Subject button
    @driver.find_element(:css, "#resource_subjects_ button").click
    # select input box and type "a" to bring up a list of subjects
    @driver.clear_and_send_keys([:css, "#resource_subjects_ input"], "Test")
  	# sleep 60
  end
end

