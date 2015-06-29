require_relative 'spec_helper'

describe "System Information" do

  before(:all) do
    backend_login

    @repo = create(:repo)
    set_repo(@repo.uri)

    (@archivist_user, @archivist_pass) = create_user
    add_user_to_archivists(@archivist_user, @repo.uri)

  end


  after(:each) do
    logout
  end

  it "should not let any old fool see this" do
    login(@archivist_user, @archivist_pass)

    $driver.find_element(:link, "System").click
    $driver.find_elements(:link, "System Information").length.should eq(0)
    $driver.get(URI.join($frontend, "/system_info"))
    assert(5) {
      $driver.find_element(:css => ".alert.alert-danger h2").text.should eq("Unable to Access Page")
    }

  end

  it "should let the admin see this" do
    login("admin", "admin")

    $driver.find_element(:link, "System").click
    $driver.find_element(:link, "System Information").click
    assert(5) {
      $driver.find_element(:css => "h3.subrecord-form-heading").text.should eq("Frontend System Information")
    }

  end
end
