require_relative 'spec_helper'

describe "Resource instances and containers" do

  before(:all) do
    @repo = create(:repo, :repo_code => "instances_test_#{Time.now.to_i}")
    set_repo @repo

    @driver = Driver.new.login_to_repo($admin, @repo)
  end

  after(:all) do
    @driver.quit
  end

  it "can attach instances to resources" do
    @driver.find_element(:link, "Create").click
    @driver.find_element(:link, "Resource").click

    @driver.clear_and_send_keys([:id, "resource_title_"], "a resource with instances")
    @driver.complete_4part_id("resource_id_%d_")
    combo = @driver.find_element(:xpath => '//div[@class="combobox-container"][following-sibling::select/@id="resource_language_"]//input[@type="text"]');
    combo.clear
    combo.click
    combo.send_keys("eng")
    combo.send_keys(:tab)
    @driver.find_element(:id, "resource_level_").select_option("collection")
    @driver.clear_and_send_keys([:id, "resource_extents__0__number_"], "10")
    @driver.find_element(:id => "resource_extents__0__extent_type_").select_option("cassettes")

    @driver.find_element(:id => "resource_dates__0__date_type_").select_option("single")
    @driver.clear_and_send_keys([:id, "resource_dates__0__begin_"], "1978")

    @driver.find_element(:css => '#resource_instances_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.find_element(:css => '#resource_instances__0__instance_type_').select_option('text')
    @driver.clear_and_send_keys([:id, "resource_instances__0__container__barcode_1_"], "123456")

    @driver.find_element(:css => "form .record-pane button[type='submit']").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource a resource with instances created/)

  end

  it "can add a location to the instance" do
    @driver.find_element(:css => '#resource_instances_ .btn.collapse-subrecord-toggle').click
    @driver.wait_for_ajax
    @driver.find_element(:css => '#resource_instances__0__container__container_locations_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.wait_for_ajax
    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__0__start_date_').attribute('value').should eq(Time.now.strftime("%Y-%m-%d"))
    }

    @driver.find_element(:css => '#resource_instances__0__container__container_locations_ .dropdown-toggle').click
    @driver.wait_for_ajax
    @driver.find_element(:css, "a.linker-create-btn").click


    @driver.clear_and_send_keys([:id, "location_building_"], "1129 W. 81st St")
    @driver.clear_and_send_keys([:id, "location_floor_"], "55")
    @driver.clear_and_send_keys([:id, "location_room_"], "66 MOO")
    @driver.clear_and_send_keys([:id, "location_coordinate_1_label_"], "Box XYZ")
    @driver.clear_and_send_keys([:id, "location_coordinate_1_indicator_"], "XYZ0001")
    @driver.click_and_wait_until_gone(:css => "#createAndLinkButton")

    @driver.find_element(:css => "form .record-pane button[type='submit']").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource a resource with instances updated/)

  end

  it "has the start_date and end_date for locations properly set" do
    @driver.find_element(:css => '#resource_instances_ .btn.collapse-subrecord-toggle').click
    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__0__start_date_').attribute('value').should eq(Time.now.strftime("%Y-%m-%d"))
    }

    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__0__end_date_').attribute('value').should eq("")
    }

    @driver.find_element(:css => "form .record-pane button[type='submit']").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource a resource with instances updated/)
  end


  it "can add a location to the instance with a temporary status" do
    @driver.navigate.refresh
    @driver.click_and_wait_until_gone(:css =>'#resource_instances_ .btn.collapse-subrecord-toggle')

    # add a new location
    @driver.find_element(:css => '#resource_instances__0__container__container_locations_ .subrecord-form-heading .btn:not(.show-all)').click
    @driver.wait_for_ajax
    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__1__start_date_').attribute('value').should eq(Time.now.strftime("%Y-%m-%d"))
    }

    # transfer location to previous
    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__1__end_date_').attribute('value').should eq("")
    }
    @driver.find_element(:id, "resource_instances__0__container__container_locations__1__status_").select_option_with_text('Previous')

    assert(5) {
      @driver.find_element(:css => '#resource_instances__0__container__container_locations__1__end_date_').attribute('value').should eq(Time.now.strftime("%Y-%m-%d"))
    }

    # enter the modal dialog
    @driver.find_element(:css, '#resource_instances__0__container__container_locations_ li.sort-enabled:not(#resource_instances__0__container__container_locations__0_) .dropdown-toggle').click
    @driver.wait_for_ajax
    @driver.find_element(:css, "#resource_instances__0__container__container_locations_  li.sort-enabled:not(#resource_instances__0__container__container_locations__0_) a.linker-create-btn").click

    @driver.find_element(:id, "location_temporary_question_").click
    @driver.find_element(:id,"location_temporary_" ).select_option_with_text('Loan')

    @driver.clear_and_send_keys([:id, "location_building_"], "TEMP LOCATION")
    @driver.clear_and_send_keys([:id, "location_barcode_"], "0987654321")

    @driver.wait_for_ajax

    @driver.find_element(:id => "createAndLinkButton").click

    @driver.find_element(:css => "form .record-pane button[type='submit']").click
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource a resource with instances updated/)

  end

  it "can be deleted" do
    @driver.find_element(:css, ".delete-record.btn").click
    @driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    #Ensure Accession no longer exists
    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Resource a resource with instances deleted") }
  end
end
