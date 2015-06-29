require_relative 'spec_helper'

describe "Permissions" do

  before(:all) do
    @perm_test_repo = "perm_test#{Time.now.to_i}_#{$$}"
    (moo, @repo_uri) = create_test_repo(@perm_test_repo, "The name of the #{@perm_test_repo}")
    (@archivist, @pass) = create_user
    add_user_to_archivists(@archivist, @repo_uri)
  end


  it "allows archivists to edit major record types by default" do
    login_to_repo(@archivist, @pass, @perm_test_repo)
    $driver.find_element(:link => 'Create').click
    $driver.find_element(:link => 'Accession').click
    $driver.find_element(:link => 'Create').click
    $driver.find_element(:link => 'Resource').click
    $driver.find_element(:link => 'Create').click
    $driver.find_element(:link => 'Digital Object').click
    logout
  end


  it "supports denying permission to edit Resources" do
    login_to_repo('admin', 'admin', @perm_test_repo)
    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Manage Groups").click

    row = $driver.find_element_with_text('//tr', /repository-archivists/)
    row.find_element(:link, 'Edit').click
    $driver.find_element(:xpath, '//input[@id="update_resource_record"]').click
    $driver.find_element(:css => 'button[type="submit"]').click
    logout
    login_to_repo(@archivist, @pass, @perm_test_repo)
    $driver.find_element(:link => 'Create').click
    $driver.ensure_no_such_element(:link, "Resource")
    logout
  end
end
