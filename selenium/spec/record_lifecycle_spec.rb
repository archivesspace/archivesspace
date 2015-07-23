require_relative 'spec_helper'

describe "Record Lifecycle" do

  before(:all) do
    login_as_repo_manager

    do_uri, @digital_object_title = create_digital_object(:title => "My digital object to test the record lifecycle")
    resource_uri, resource_title = create_resource(:title => "My resource to test the record lifecycle", :instances => [{:instance_type => "digital_object", :digital_object => {:ref => do_uri}}])
    create_archival_object(:title => nil, :dates => [{:expression => "1981 - present", :date_type => "single", :label => "creation"}], :resource => {:ref => resource_uri}, :instances => [{:instance_type => "digital_object", :digital_object => {:ref => do_uri}}])

    @accession_title = create_accession(:title => "My accession to test the record lifecycle")
    run_index_round
    logout
  end

  after(:each) do
    logout
  end

  after(:all) do
    $accession_url = nil
  end


  it "can suppress an Accession" do
    login_as_repo_manager
    # make sure we can see suppressed records
    $driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    $driver.find_element(:link, "My Repository Preferences").click

    elt = $driver.find_element(:xpath, '//input[@id="preference_defaults__show_suppressed_"]')
    unless elt[@checked]
      elt.click
      $driver.find_element(:css => 'button[type="submit"]').click
    end

    # Navigate to the Accession
    $driver.clear_and_send_keys([:id, "global-search-box"], @accession_title)
    $driver.find_element(:id, "global-search-button").click
    $driver.find_element(:link, "View").click
    $accession_url = $driver.current_url

    # Suppress the Accession
    $driver.find_element(:css, ".suppress-record.btn").click
    $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} suppressed") }
    assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited') }

    run_index_round

    # Try to navigate to the edit form
    $driver.get("#{$accession_url}/edit")

    assert(5) { $driver.current_url.should eq($accession_url) }
    assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited') }

  end


  it "an archivist can't see a suppressed Accession" do
    login_as_archivist
    # check the listing
    $driver.find_element(:link, "Browse").click
    $driver.find_element(:link, "Accessions").click

    $driver.find_element_with_text('//h2', /Accessions/)

    # No element found
    $driver.find_element_with_text('//td', /#{@accession_title}/, true, true).should eq(nil)

    # check the accession url
    $driver.get($accession_url)
    $driver.find_element_with_text('//h2', /Record Not Found/)

  end


  it "can unsuppress an Accession" do
    login_as_repo_manager

    $driver.get($accession_url)

    # Unsuppress the Accession
    $driver.find_element(:css, ".unsuppress-record.btn").click
    $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} unsuppressed") }
  end


  it "can delete an Accession" do
    login_as_repo_manager
    $driver.get($accession_url)
    # Delete the accession
    $driver.find_element(:css, ".delete-record.btn").click
    $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    #Ensure Accession no longer exists
    assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession_title} deleted") }

    run_index_round

    # hmm boo.. refresh the page now that the indexer is refreshed
    $driver.navigate.refresh
    $driver.find_element_with_text('//h2', /Accessions/)

    # No element found
    $driver.find_element_with_text('//td', /#{@accession_title}/, true, true).should eq(nil)

    # Navigate back to the accession's page
    $driver.get($accession_url)
    assert(5) {
      $driver.find_element_with_text('//h2', /Record Not Found/)
    }
    $driver.navigate.to $frontend
  end


  it "can suppress a Digital Object" do
    login_as_repo_manager
    # Navigate to the Digital Object
    $driver.clear_and_send_keys([:id, "global-search-box"], @digital_object_title)
    $driver.find_element(:id, "global-search-button").click
    $driver.find_element(:link, "View").click
    digital_object_url = $driver.current_url
    $driver.find_element(:link, "Edit").click
    digital_object_edit_url = $driver.current_url

    # Suppress the Digital Object
    $driver.find_element(:css, ".suppress-record.btn").click
    $driver.find_element(:css, "#confirmChangesModal #confirmButton").click

    assert(5) { $driver.find_element(:css => "div.alert.alert-success").text.should eq("Digital Object #{@digital_object_title} suppressed") }
    assert(5) { $driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited') }

    run_index_round

    # Try to navigate to the edit form
    $driver.navigate.to(digital_object_edit_url)
    $driver.wait_for_ajax
    # there seems to be some oddities with the JS and the URL...they don't
    # matter to the app

    url = digital_object_edit_url.split("#").first

    expect {
      assert(5) {
        raise "Can't reload url #{digital_object_edit_url}" unless $driver.current_url.include?(url)
      }
    }.not_to raise_error

    $driver.wait_for_ajax
    $driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited')
  end

end
