require_relative 'spec_helper'

describe "Permissions" do

  before(:all) do
    @repo = create(:repo, :repo_code => "perm_test_#{Time.now.to_i}")
    set_repo @repo

    @archivist = create_user(@repo => ['repository-archivists'])
    @driver = Driver.new.login_to_repo(@archivist_user, @repo)
  end


  after(:all) do
    @driver.logout.quit
  end


  it "allows archivists to edit major record types by default" do
    @driver.login_to_repo(@archivist, @repo)
    @driver.find_element(:link => 'Create').click
    @driver.find_element(:link => 'Accession').click
    @driver.find_element(:link => 'Create').click
    @driver.find_element(:link => 'Resource').click
    @driver.find_element(:link => 'Create').click
    @driver.find_element(:link => 'Digital Object').click
    @driver.logout
  end


  it "supports denying permission to edit Resources" do
    @driver.login_to_repo($admin, @repo)
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.find_element(:link, "Manage Groups").click

    row = @driver.find_element_with_text('//tr', /repository-archivists/)
    row.find_element(:link, 'Edit').click
    @driver.find_element(:xpath, '//input[@id="update_resource_record"]').click
    @driver.find_element(:css => 'button[type="submit"]').click
    @driver.login_to_repo(@archivist, @repo)
    @driver.find_element(:link => 'Create').click
    @driver.ensure_no_such_element(:link, "Resource")
  end
end
