require_relative 'spec_helper'

describe "Permissions" do

  before(:all) do
    @repo = create(:repo, :repo_code => "perm_test_#{Time.now.to_i}")
    set_repo @repo

    @archivist = create_user(@repo => ['repository-archivists'])
    @driver = Driver.get.login_to_repo(@archivist_user, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "allows archivists to edit major record types by default" do
    @driver.login_to_repo(@archivist, @repo)
    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Accession')
    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Resource')
    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Digital Object')
    @driver.logout
  end


  it "supports denying permission to edit Resources" do
    @driver.login_to_repo($admin, @repo)
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.click_and_wait_until_gone(:link, "Manage Groups")

    row = @driver.find_element_with_text('//tr', /repository-archivists/)
    row.click_and_wait_until_gone(:link, 'Edit')
    @driver.find_element(:xpath, '//input[@id="update_resource_record"]').click
    @driver.click_and_wait_until_gone(:css => 'button[type="submit"]')
    @driver.login_to_repo(@archivist, @repo)
    @driver.find_element(:link => 'Create').click
    @driver.ensure_no_such_element(:link, "Resource")
  end
end
