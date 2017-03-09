require_relative 'spec_helper'

describe "Context Sensitive Help" do

  before(:all) do
    @repo = create(:repo, :repo_code => "notes_test_#{Time.now.to_i}")
    set_repo @repo

    @manager = create_user(@repo => ['repository-managers'])
    @driver = Driver.get.login_to_repo(@manager, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "displays a clickable tooltip for a field label" do
    # navigate to the Accession form
    @driver.find_element(:link, "Create").click
    @driver.click_and_wait_until_gone(:link, "Accession")

    # click on a field label

    # Use JQuery to trigger the handler to avoid hovering over the element too
    @driver.find_element(:css, "label[for='accession_title_']")
    @driver.execute_script("$('label[for=\"accession_title_\"]').triggerHandler(\"click\")")

    @driver.find_element(:css, ".tooltip.archivesspace-help")

    # can hide the tooltip
    @driver.find_element(:css, ".tooltip.archivesspace-help .tooltip-close").click

    assert(5) {
      @driver.ensure_no_such_element(:css, ".tooltip.archivesspace-help .tooltip-close")
    }
    @driver.complete_4part_id("accession_id_%d_")
    @driver.clear_and_send_keys([:id, "accession_accession_date_"], "2012-01-01")
    @driver.find_element(:css => "form#accession_form button[type='submit']").click 
  end

end
