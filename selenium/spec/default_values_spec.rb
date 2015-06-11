require_relative 'spec_helper'

describe "Default Form Values" do

  before(:all) do
    backend_login

    @repo = create(:repo)
    set_repo(@repo.uri)

    (@archivist_user, @archivist_pass) = create_user
    add_user_to_archivists(@archivist_user, @repo.uri)

    login("admin", "admin")
    select_repo(@repo.repo_code)

    $driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    $driver.find_element(:link, "My Repository Preferences").click

    checkbox = $driver.find_element(:id => "preference_defaults__default_values_")

    if !checkbox.attribute('checked')
      checkbox.click
      $driver.find_element(:css => 'button[type="submit"]').click
      $wait.until { $driver.find_element(:css => ".alert-success") }
    end

    logout
  end


  before(:each) do
    login("admin", "admin")
    select_repo(@repo.repo_code)
  end


  after(:each) do
    logout
  end


  it "will let an admin create default accession values" do
    $driver.get("#{$frontend}/accessions")    

    $driver.find_element_with_text("//a", /Edit Default Values/).click

    $driver.clear_and_send_keys([:id, "accession_title_"], "DEFAULT TITLE")

    $driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    $driver.get("#{$frontend}/accessions/new")

    $driver.find_element(:css => "#accession_title_").text.should eq("DEFAULT TITLE")
  end


  it "won't let a regular archivist edit default accession values" do
    logout
    login(@archivist_user, @archivist_pass)
    select_repo(@repo.repo_code)

    $driver.get("#{$frontend}/accessions")    

    $driver.find_elements(:link, "Edit Default Values").length.should eq(0)    
  end

end
