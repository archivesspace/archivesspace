require_relative 'spec_helper'

describe "Default Form Values" do

  before(:all) do

    @repo = create(:repo, :repo_code => "default_values_test_#{Time.now.to_i}")
    set_repo @repo

    @archivist_user = create_user(@repo => ['repository-archivists'])

    @driver = Driver.new.login_to_repo($admin, @repo)

    @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
    @driver.find_element(:link, "My Repository Preferences").click

    checkbox = @driver.find_element(:id => "preference_defaults__default_values_")

    if !checkbox.attribute('checked')
      checkbox.click
      @driver.find_element(:css => 'button[type="submit"]').click
      @driver.find_element(:css => ".alert-success")
    end

  end

  after(:all) do
    @driver.quit
  end


  it "will let an admin create default accession values" do
    @driver.get("#{$frontend}/accessions")

    @driver.find_element_with_text("//a", /Edit Default Values/).click

    @driver.clear_and_send_keys([:id, "accession_title_"], "DEFAULT TITLE")

    @driver.click_and_wait_until_gone(:css => "form#accession_form button[type='submit']")

    @driver.get("#{$frontend}/accessions/new")

    @driver.find_element(:css => "#accession_title_").text.should eq("DEFAULT TITLE")
  end


  it "won't let a regular archivist edit default accession values" do
    @driver.login_to_repo(@archivist_user, @repo)

    @driver.get("#{$frontend}/accessions")

    @driver.find_elements(:link, "Edit Default Values").length.should eq(0)
  end

end
