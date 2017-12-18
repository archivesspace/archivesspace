require_relative 'spec_helper'

describe "Merging and transfering resources" do

  before(:all) do
    @repo = create(:repo, :repo_code => "transfer_test_#{Time.now.to_i}")
    set_repo(@repo)

    @target_repo = create(:repo, :repo_code => "transfer_test_target_#{Time.now.to_i}")

    @driver = Driver.get.login_to_repo($admin, @repo)

    @resource = create(:resource)
    @resource2 = create(:resource)
    @resource3 = create(:resource)


    @digital_objects = (0...6).map {|i| create(:digital_object)}

    @aoset2 = (0...10).map { create(:archival_object, :resource => {'ref' => @resource2.uri}) }
    @aoset3 = (0...10).map { create(:archival_object, :resource => {'ref' => @resource3.uri}) }

    run_index_round
  end

  after(:all) do
    @driver.quit
  end


  it "can transfer a resource to another repository and open it for editing" do
    @driver.get_edit_page(@resource)
    @driver.find_element(:link, "Transfer").click
    @driver.find_element(:id, "transfer_ref_").select_option_with_text(@target_repo.repo_code)
    @driver.find_element(:css => ".transfer-button").click
    @driver.find_element(:css, "#confirmButton").click
    @driver.wait_for_ajax

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Transfer Successful/)

    run_all_indexers

    @driver.select_repo(@target_repo)

    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Resources")

   begin
      @driver.find_element_orig(:xpath => "//td[contains(text(), '#{@resource.title}')]")
    rescue Selenium::WebDriver::Error::NoSuchElementError
      run_all_indexers
      sleep(1)
      @driver.find_element(:xpath => "//td[contains(text(), '#{@resource.title}')]")
    end


  end



  it "can merge a resource into a resource" do
    @driver.select_repo(@repo)

    @driver.get_edit_page(@resource2)

    @driver.find_element(:link, "Merge").click
    @driver.wait_for_ajax

    # spaces in the search string seem to through off the token search, so:
    search_string = @resource3.title.sub(/-\s.*/, "").strip
    @driver.clear_and_send_keys([:id, "token-input-merge_ref_"], search_string )
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css, "button.merge-button").click

    @driver.find_element_with_text("//h3", /Merge into this record\?/)
    @driver.click_and_wait_until_gone(:css, "button#confirmButton")

    (@aoset2 + @aoset3).each do |ao|
      assert(5) {
        @driver.find_element(:id => tree_node(ao).tree_id)
      }
    end
  end
  
  it "can merge an archival objects into a resource" do
    @driver.select_repo(@repo)

    @driver.get_edit_page(@aoset2.first)

    @driver.find_element(:link, "Transfer").click

    # spaces in the search string seem to through off the token search, so:
    search_string = @resource2.title.sub(/-\s.*/, "").strip
    @driver.clear_and_send_keys([:id, "token-input-transfer_ref_"], search_string )
    sleep(1)
    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css, "button.transfer-button").click
    @driver.wait_for_ajax


    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Successfully transferred Archival Object/)

    @driver.get_edit_page(@resource2)
    @driver.wait_for_ajax

    (@aoset2 + @aoset3).each do |ao|
      assert(5) {
        @driver.find_element(:id => tree_node(ao).tree_id)
      }
    end
  end


  it "can merge a digital object into a digital object" do
    # get a new pair each time in case the test fails
    # after the target is merged
    merger = @digital_objects.shift
    target = @digital_objects.shift

    @driver.get_edit_page(merger)

    @driver.find_element(:link, "Merge").click

    # spaces in the search string seem to through off the token search, so:
    search_string = target.title.sub(/-\s.*/, "").strip
    token_input = @driver.find_element(:id, "token-input-merge_ref_")
    @driver.typeahead_and_select( token_input,  search_string )


    @driver.find_element(:css, "button.merge-button").click

    @driver.wait_for_ajax

    @driver.find_element_with_text("//h3", /Merge into this record\?/)
    @driver.find_element(:css, "button#confirmButton").click
    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Digital object(s) Merged") }
  end
end
