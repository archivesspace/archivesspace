require_relative 'spec_helper'

describe "Record Lifecycle" do

  before(:all) do
    @repo = create(:repo, :repo_code => "lifecycle_test_#{Time.now.to_i}")
    set_repo @repo

    @manager_user = create_user(@repo => ['repository-managers'])
    @archivist_user = create_user(@repo => ['repository-archivists'])


    @driver = Driver.get.login_to_repo(@manager_user, @repo)

    @do = create(:digital_object)

    @resource = create(:resource,
                       :instances => [
                                      {
                                        :instance_type => "digital_object",
                                        :digital_object => {:ref => @do.uri}}
                                     ])

    create(:archival_object,
           :title => nil,
           :dates => [{:expression => "1981 - present", :date_type => "single", :label => "creation"}], :resource => {:ref => @resource.uri}, :instances => [{:instance_type => "digital_object", :digital_object => {:ref => @do.uri}}])

    @accession = create(:accession,
                        :title => "My accession to test the record lifecycle")
    run_index_round
  end

  after(:all) do
    @driver.quit
  end


  it "can suppress an Accession" do

    # make sure we can see suppressed records
    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.click_and_wait_until_gone(:link, "My Repository Preferences")

    elt = @driver.find_element(:xpath, '//input[@id="preference_defaults__show_suppressed_"]')
    unless elt.attribute('checked')
      elt.click
      @driver.click_and_wait_until_gone(:css => 'button[type="submit"]')
    end

    # Navigate to the Accession
    @driver.get_edit_page(@accession)

    # Suppress the Accession
    @driver.find_element(:css, ".suppress-record.btn").click
    @driver.click_and_wait_until_gone(:css, "#confirmChangesModal #confirmButton")

    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession.title} suppressed") }
    assert(5) { @driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited') }

    run_index_round

    # Try to navigate to the edit form
    @driver.get_edit_page(@accession)
    @driver.find_element(:css => "div.alert.alert-info").text.should eq('Accession is suppressed and cannot be edited')
  end


  it "an archivist can't see a suppressed Accession" do
    @driver.login_to_repo(@archivist_user, @repo)
    # check the listing
    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Accessions")

    @driver.find_element_with_text('//h2', /Accessions/)

    # No element found
    @driver.find_element_with_text('//td', /#{@accession.title}/, true, true).should eq(nil)

    # check the accession url
    @driver.get_edit_page(@accession)
    expect {
      @driver.find_element_with_text('//h2', /Record Not Found/)
      }.to_not raise_error

  end


  it "can unsuppress an Accession" do
    @driver.login_to_repo(@manager_user, @repo)

    @driver.get_edit_page(@accession)

    # Unsuppress the Accession
    @driver.find_element(:css, ".unsuppress-record.btn").click
    @driver.click_and_wait_until_gone(:css, "#confirmChangesModal #confirmButton")

    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession.title} unsuppressed") }
  end


  it "can delete an Accession" do
    @driver.login_to_repo(@manager_user, @repo)

    @driver.get_edit_page(@accession)

    # Delete the accession
    @driver.find_element(:css, ".delete-record.btn").click
    @driver.click_and_wait_until_gone(:css, "#confirmChangesModal #confirmButton")

    #Ensure Accession no longer exists
    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Accession #{@accession.title} deleted") }

    run_index_round

    # hmm boo.. refresh the page now that the indexer is refreshed
    @driver.navigate.refresh
    @driver.find_element_with_text('//h2', /Accessions/)

    # No element found
    @driver.find_element_with_text('//td', /#{@accession.title}/, true, true).should eq(nil)

    # Navigate back to the accession's page
    @driver.get_edit_page(@accession)
    assert(5) {
      @driver.find_element_with_text('//h2', /Record Not Found/)
    }
    @driver.go_home
  end


  it "can suppress a Digital Object" do
    @driver.login_to_repo(@manager_user, @repo)
    # Navigate to the Digital Object
    @driver.get_edit_page(@do)

    # Suppress the Digital Object
    @driver.find_element(:css, ".suppress-record.btn").click
    @driver.click_and_wait_until_gone(:css, "#confirmChangesModal #confirmButton")

    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Digital Object #{@do.title} suppressed") }
    assert(5) { @driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited') }

    run_index_round

    # Try to navigate to the edit form
    @driver.get_edit_page(@do)
    @driver.wait_for_ajax
    # # there seems to be some oddities with the JS and the URL...they don't
    # # matter to the app

    # url = digital_object_edit_url.split("#").first

    # expect {
    #   assert(5) {
    #     raise "Can't reload url #{digital_object_edit_url}" unless @driver.current_url.include?(url)
    #   }
    # }.not_to raise_error

    # @driver.wait_for_ajax
    @driver.find_element(:css => "div.alert.alert-info").text.should eq('Digital Object is suppressed and cannot be edited')
  end

end
