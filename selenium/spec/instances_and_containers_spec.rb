require_relative 'spec_helper'

describe "Resource instances and containers" do

  before(:all) do
    @repo = create(:repo, :repo_code => "instances_test_#{Time.now.to_i}")
    set_repo @repo

    @resource = create(:resource)

    @location_a = create(:location)
    @location_b = create(:location, {
                           :temporary => 'conservation'
                           })
    container_location = build(:container_location, {
                                 :ref => @location_a.uri
                               })
    @container = create(:top_container, {
                          :container_locations => [container_location]
                        })

    # Some containers for searching
    ("A".."E").each do |l|
        create(:top_container, {
                 :indicator => "Letter #{l}",
                 :container_locations => [container_location]
               })
    end

    run_all_indexers

    @driver = Driver.new.login_to_repo($admin, @repo)
  end

  before(:each) do
    @driver.navigate.to("#{$frontend}")
  end


  after(:all) do
    @driver.quit
  end


  it "searches containers and performs bulk operations" do

    @driver.navigate.to("#{$frontend}/top_containers")

    @driver.find_element(:id => 'q').send_keys("Letter")
    @driver.find_element(:css => "input.btn").click

    @driver.wait_for_ajax

    results = @driver.find_element(:id => "bulk-operation-results")

    results.find_elements(:css => "tbody tr").length.should eq(5)

    # Now sort by indicator
    @driver.find_element(:css => "th[data-column='4'] div.tablesorter-header-inner").click

    @driver.wait_for_ajax

    
    @driver.find_element(:css => "#bulk-operation-results tbody tr:first-child td.top-container-indicator").text.should eq('Letter E')

    @driver.find_element(:css => "#bulk-operation-results tbody tr:first-child td:first-child input").click

    # Now bulk update Letter E's ILD #
    @driver.find_element(:css => ".bulk-operation-toolbar:first-child a.dropdown-toggle").click

    @driver.find_element(:id => "bulkActionUpdateIlsHolding").click

    modal = @driver.find_element(:id => "bulkUpdateModal")

    modal.find_element(:id => "ils_holding_id").send_keys("xyzpdq")

    modal.find_element(:css => "button[type='submit']").click

    modal = @driver.find_element(:id => "bulkUpdateModal")

    expect {
      modal.find_element_with_text('//div[contains(@class, "alert-success")]', /Top .+ updated/)
    }.to_not raise_error

    modal.find_element(:css => ".modal-footer button").click

    @driver.click_and_wait_until_gone(:css => "#bulk-operation-results tbody tr:first-child td:last-child a:first-child")

    @driver.find_element(:css => ".form-group:nth-child(3) div.label-only").text.should eq("xyzpdq")
  end


  it "can attach instances to resources and create containers and locations along the way" do

    @driver.navigate.to("#{$frontend}#{@resource.uri.sub(/\/repositories\/\d+/, '')}/edit")
    @driver.find_element(:css => '#resource_instances_ .subrecord-form-heading .btn[data-instance-type="sub-container"]').click
    @driver.find_element(:css => '#resource_instances__0__instance_type_').select_option('text')

    # new
    elt = @driver.test_find_element(:id => "resource_instances__0__container_")
    elt.find_element(:css => 'a.dropdown-toggle').click
    elt.find_element(:css => 'a.linker-create-btn').click
    modal = @driver.test_find_element(:css => '#resource_instances__0__sub_container__top_container__ref__modal')

    modal.find_element(:css => '#top_container_indicator_').send_keys("foo")
    modal.find_element(:css => '#top_container_barcode_').send_keys("1234567")

    elt = modal.find_element(:css => '#top_container_container_locations_')
    elt.find_element(:css => 'h3 > button').click

    assert(5) {
      elt.find_element(:css => '#top_container_container_locations__0__start_date_').attribute('value').should eq(Time.now.strftime("%Y-%m-%d"))
    }

    assert(5) {
      elt.find_element(:css => '#top_container_container_locations__0__end_date_').attribute('value').should eq("")
    }

    elt.find_element(:css => '.dropdown-toggle.locations').click
    sleep(2) 
    @driver.wait_for_ajax
    elt.find_element(:css, "a.linker-create-btn").click

    sleep(2)
    loc_modal = @driver.find_element(:id => 'top_container_container_locations__0__ref__modal')

    loc_modal.clear_and_send_keys([:id, "location_building_"], "1129 W. 81st St")
    loc_modal.clear_and_send_keys([:id, "location_floor_"], "55")
    loc_modal.clear_and_send_keys([:id, "location_room_"], "66 MOO")
    loc_modal.clear_and_send_keys([:id, "location_coordinate_1_label_"], "Box XYZ")
    loc_modal.clear_and_send_keys([:id, "location_coordinate_1_indicator_"], "XYZ0001")
    loc_modal.click_and_wait_until_gone(:css => "#createAndLinkButton")

    # re-find our original modal
    modal = @driver.test_find_element(:css => '#resource_instances__0__sub_container__top_container__ref__modal')
    modal.find_element(:id => 'createAndLinkButton').click

    @driver.find_element(:css => "form .record-pane button[type='submit']").click

    expect {
      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Resource .+ updated/)
    }.to_not raise_error
  end


  it "can add a location with a previous status to a top container" do

    @driver.navigate.to("#{$frontend}#{@container.uri.sub(/\/repositories\/\d+/, '')}/edit")

    section = @driver.find_element(:id => 'top_container_container_locations_')
    section.find_element(:css => "button.btn-sm:nth-child(1)").click

    new_loc = @driver.find_element(:css => "li.sort-enabled[data-index='1']")

    new_loc.find_element(:id, "top_container_container_locations__1__status_").select_option_with_text('Previous')

    token_input = new_loc.find_element(:css => "li.token-input-input-token input")
    token_input.clear
    token_input.click
    token_input.send_keys(@location_b.building)

    @driver.find_element(:css, "li.token-input-dropdown-item2").click

    @driver.find_element(:css => "form .record-pane button[type='submit']").click

    # it won't let you save a 'Previous' location without an end date
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /End Date.*Status.*Previous.*/)
    }.to_not raise_error

    new_loc = @driver.find_element(:css => "li.sort-enabled[data-index='1']")

    new_loc.find_element(:id, "top_container_container_locations__1__end_date_").send_keys('2015-01-02')

    @driver.find_element(:css => "form .record-pane button[type='submit']").click

    expect {
      @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Top Container Updated/)
    }.to_not raise_error
  end
end
