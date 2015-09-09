require_relative 'spec_helper'

describe "Merging and transfering resources" do

  before(:all) do
    backend_login
    @repo = create(:repo)
    set_repo(@repo.uri)

    @target_repo = create(:repo)

    login_to_repo("admin", "admin", @repo)

    @resource = create(:resource)
    @resource2 = create(:resource)
    @resource3 = create(:resource)

    @do1 = create(:digital_object)
    @do2 = create(:digital_object)
    @do3 = create(:digital_object)

    @aoset2 = (0...10).map { create(:archival_object, :resource => {'ref' => @resource2.uri}) }
    @aoset3 = (0...10).map { create(:archival_object, :resource => {'ref' => @resource3.uri}) }

    run_index_round
  end

  before(:each) do
  end

  after(:all) do
    logout
  end


  it "can transfer a resource to another repository and open it for editing", :retry => 2, :retry_wait => 10 do
    $driver.get("#{$frontend}#{@resource.uri.sub(/\/repositories\/\d+/, '')}/edit")

    $driver.find_element(:link, "Transfer").click
    $driver.find_element(:id, "transfer_ref_").select_option_with_text(@target_repo.repo_code)
    $driver.find_element(:css => ".transfer-button").click
    $driver.find_element(:css, "#confirmButton").click
    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Transfer Successful/)

    run_all_indexers

    select_repo(@target_repo.repo_code)

    $driver.find_element(:link, "Browse").click
    $driver.find_element(:link, "Resources").click

    $driver.find_element(:xpath => "//td[contains(text(), '#{@resource.title}')]")

    $driver.get("#{$frontend}#{@resource.uri.sub(/\/repositories\/\d+/, '')}/edit")
  end



  it "can merge a resource into a resource", :retry => 2, :retry_wait => 10 do
    select_repo(@repo.repo_code)

    $driver.get("#{$frontend}#{@resource2.uri.sub(/\/repositories\/\d+/, '')}/edit")

    $driver.find_element(:link, "Merge").click

    # spaces in the search string seem to through off the token search, so:
    search_string = @resource3.title.sub(/-\s.*/, "").strip
    $driver.clear_and_send_keys([:id, "token-input-merge_ref_"], search_string )
    sleep(1)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:css, "button.merge-button").click

    $driver.wait_for_ajax

    $driver.find_element_with_text("//h3", /Merge into this record\?/)
    $driver.find_element(:css, "button#confirmButton").click
    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource\(s\) Merged/)

    (@aoset2 + @aoset3).each do |ao|
      assert(5) {
        $driver.find_element(:id => js_node(ao).li_id)
      }
    end
  end


  it "can merge a digital object into a digital object", :retry => 2, :retry_wait => 10 do

    select_repo(@repo.repo_code)

    $driver.get_edit_page(@do1)

    $driver.find_element(:link, "Merge").click

    # spaces in the search string seem to through off the token search, so:
    search_string = @do2.title.sub(/-\s.*/, "").strip
    $driver.clear_and_send_keys([:id, "token-input-merge_ref_"], search_string )
    sleep(1)
    $driver.find_element(:css, "li.token-input-dropdown-item2").click

    $driver.find_element(:css, "button.merge-button").click

    $driver.wait_for_ajax

    $driver.find_element_with_text("//h3", /Merge into this record\?/)
    $driver.find_element(:css, "button#confirmButton").click
    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Digital object\(s\) Merged/i)

  end
end
