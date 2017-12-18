require_relative 'spec_helper'

describe "Space Calculator" do

  before(:all) do
    @repo = create(:repo, :repo_code => "space_calculator_#{Time.now.to_i}")
    set_repo @repo

    @manager_user = create_user(@repo => ['repository-managers'])

    @container_profile = create(:container_profile, {
      :dimension_units => "inches",
      :width => "10",
      :height => "10",
      :depth => "10",
      :stacking_limit => "2",
    })

    @location_profile = create(:location_profile, {
      :dimension_units => "inches",
      :width => "100",
      :height => "20",
      :depth => "10"
    })

    @location = create(:location, {
      :floor => "5",
      :room => "1A",
      :area => "Shadowy Corner",
      :location_profile => {
        :ref => @location_profile.uri
      }
    })

    @top_container = create(:top_container, {
      :container_profile => {
        :ref => @container_profile.uri
      }
    })

    run_all_indexers

    @driver = Driver.get.login_to_repo(@manager_user, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "can access the calculator via the container profile toolbar" do
    @driver.navigate.to("#{$frontend}/container_profiles/#{@container_profile.id}")
    @driver.find_element(:id, "showSpaceCalculator").click
    @driver.find_element(:id, "spaceCalculatorModal")
  end

  it "can run the calculator for a building, floor, room and area combination" do
    @driver.find_element(:id => "building").select_option(@location.building)
    @driver.find_element(:id => "floor").select_option(@location.floor)
    @driver.find_element(:id => "room").select_option(@location.room)
    @driver.find_element(:id => "area").select_option(@location.area)

    @driver.find_element(:css => "#spaceCalculatorModal #space_calculator .btn.btn-primary").click

    row = @driver.find_element(:css => "#tabledSearchResults tr.has-space")
    row.find_element(:css => ".space .glyphicon-ok-sign.text-success")
    row.find_element(:css => ".location").text.should eq(@location.title)
    row.find_element(:css => ".location-profile").text.should match(/^#{@location_profile.name}/)
    row.find_element(:css => ".count").text.should eq("20")

    @driver.click_and_wait_until_gone(:css => "#spaceCalculatorModal .modal-footer .btn-primary")
  end

  it "can access the calculator from a top container form" do
    # admin only default user with manage_container_record permission
    @driver.logout.login_to_repo($admin, @repo)

    @driver.navigate.to("#{$frontend}/top_containers/#{@top_container.id}/edit")
    @driver.find_element(:css => "#top_container_container_locations_ .subrecord-form-heading .btn").click
    @driver.find_element(:css => "#top_container_container_locations_ .linker-wrapper .btn.locations").click
    @driver.wait_for_dropdown
    @driver.find_element(:link => "Find with Space Calculator").click

    @driver.find_element(:id, "spaceCalculatorModal")
  end

  it "can run the calculator for a specific location" do
    @driver.find_element(:link => "By Location(s)").click
    @driver.clear_and_send_keys([:id, "token-input-location"], @location.title)
    input_token = @driver.find_element(:id, "token-input-location")
    @driver.typeahead_and_select( input_token, @location.title ) 


    @driver.find_element(:css => "#spaceCalculatorModal #space_calculator .btn.btn-primary").click

    row = @driver.find_element(:css => "#tabledSearchResults tr.has-space")
    row.find_element(:css => ".space .glyphicon-ok-sign.text-success")
    row.find_element(:css => ".location").text.should eq(@location.title)
    row.find_element(:css => ".location-profile").text.should match(/^#{@location_profile.name}/)
    row.find_element(:css => ".count").text.should eq("20")
  end

  it "can select a location from the calculator results to populate the Container's Location field" do
    # a row with space exists
    row = @driver.find_element(:css => "#tabledSearchResults tr.has-space")

    # clicking the row will select the row
    @driver.execute_script("$('#tabledSearchResults tr.has-space td:first').click()");

    # the radio should be checked
    expect(@driver.execute_script("return $('#linker-item__locations_#{@location.id}').is(':checked')")).to be_truthy

    # and the row selected
    expect(row.attribute('class')).to include('selected')

    # the add button will now be enabled
    @driver.find_element(:css => "#spaceCalculatorModal .modal-footer #addSelectedButton:not([disabled])").click
    @driver.find_element(:css, "#top_container_container_locations_ ul.token-input-list").text.should match(/#{Regexp.quote(@location.title)}/)
    @driver.find_element(:css => ".record-pane .form-actions .btn.btn-primary").click
  end
end
