require_relative 'spec_helper'

describe "System Information" do

  before(:all) do
    @repo = create(:repo)
    set_repo(@repo)

    @archivist_user = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get
  end


  after(:all) do
    @driver.quit
  end

  it "should not let any old fool see this" do
    @driver.login_to_repo(@archivist_user, @repo)

    @driver.find_element(:link, "System").click
    @driver.find_elements(:link, "System Information").length.should eq(0)
    @driver.get(URI.join($frontend, "/system_info"))
    assert(5) {
      @driver.find_element(:css => ".alert.alert-danger h2").text.should eq("Unable to Access Page")
    }

  end

  it "should let the admin see this" do
    @driver.login_to_repo($admin, @repo)

    @driver.find_element(:link, "System").click
    @driver.find_element(:link, "System Information").click
    assert(5) {
      @driver.find_element(:css => "h3.subrecord-form-heading").text.should eq("Frontend System Information")
    }
  end
end
