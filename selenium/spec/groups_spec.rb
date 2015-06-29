require_relative 'spec_helper'

describe "Groups" do

  before(:all) do
    @can_manage_repo = "group_manage#{Time.now.to_i}_#{$$}"
    @can_view_repo = "group_view#{Time.now.to_i}_#{$$}"

    (@user, @pass) = create_user

    create_test_repo(@can_manage_repo, "manage", false)
    create_test_repo(@can_view_repo, "view", false)
    # wait for notification to fire (which can take up to 5 seconds)
    sleep 5
    login("admin", "admin")
  end


  after(:all) do
    logout
  end


  it "can assign a user to the archivist group" do
    select_repo(@can_manage_repo)

    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Manage Groups").click

    row = $driver.find_element_with_text('//tr', /repository-archivists/)
    row.find_element(:link, 'Edit').click

    $driver.clear_and_send_keys([:id, 'new-member'],(@user))
    $driver.find_element(:id, 'add-new-member').click
    $driver.find_element(:css => 'button[type="submit"]').click
  end


  it "can assign the test user to the viewers group of the first repository" do
    select_repo(@can_view_repo)

    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Manage Groups").click

    row = $driver.find_element_with_text('//tr', /repository-viewers/)
    row.find_element(:css, '.btn').click

    $driver.clear_and_send_keys([:id, 'new-member'],(@user))
    $driver.find_element(:id, 'add-new-member').click
    $driver.find_element(:css => 'button[type="submit"]').click
  end


  it "reports errors when attempting to create a Group with missing data" do
    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Manage Groups").click
    $driver.find_element(:link, "Create Group").click
    $driver.find_element(:css => "form#new_group button[type='submit']").click
    expect {
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Group code - Property is required but was missing/)
    }.to_not raise_error
    $driver.find_element(:link, "Cancel").click
  end


  it "can create a new Group" do
    $driver.find_element(:link, "Create Group").click
    $driver.clear_and_send_keys([:id, 'group_group_code_'], "goo")
    $driver.clear_and_send_keys([:id, 'group_description_'], "Goo group to group goo")
    $driver.find_element(:id, "view_repository").click
    $driver.find_element(:css => "form#new_group button[type='submit']").click
    expect {
      $driver.find_element_with_text('//tr', /goo/)
    }.to_not raise_error
  end


  it "reports errors when attempting to update a Group with missing data" do
    $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
    $driver.clear_and_send_keys([:id, 'group_description_'], "")
    $driver.find_element(:css => "form#new_group button[type='submit']").click
    expect {
      $driver.find_element_with_text('//div[contains(@class, "error")]', /Description - Property is required but was missing/)
    }.to_not raise_error
    $driver.find_element(:link, "Cancel").click
  end


  it "can edit a Group" do
    $driver.find_element_with_text('//tr', /goo/).find_element(:link, "Edit").click
    $driver.clear_and_send_keys([:id, 'group_description_'], "Group to gather goo")
    $driver.find_element(:css => "form#new_group button[type='submit']").click
    expect {
      $driver.find_element_with_text('//tr', /Group to gather goo/)
    }.to_not raise_error
  end


  it "can get a list of usernames matching a string" do
    $driver.get(URI.join($frontend, "/users/complete?query=#{URI.escape(@user)}"))
    $driver.page_source.should match(/#{@user}/)
    $driver.get(URI.join($frontend))
  end

  it "can log out of the admin account" do
    logout
  end


  it "can log in with the user just created" do
    $driver.find_element(:link, "Sign In").click
    $driver.clear_and_send_keys([:id, 'user_username'], @user)
    $driver.clear_and_send_keys([:id, 'user_password'], @pass)
    $driver.find_element(:id, 'login').click

    assert(5) { $driver.find_element(:css => "span.user-label").text.should match(/#{@user}/) }
  end


  it "can select the second repository and find the create link" do
    select_repo(@can_manage_repo)

    # Wait until it's selected
    $driver.find_element_with_text('//div[contains(@class, "alert-success")]', /#{@can_manage_repo}/)
    $driver.find_element(:link, "Create")
  end


  it "can modify the user's groups for a repository via the Manage Access listing" do
    logout
    login("admin", "admin")

    # change @can_manage_repo to a view only
    select_repo(@can_manage_repo)

    $driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    $driver.find_element(:link, "Manage User Access").click

    while true
      # Wait for the table to load
      $driver.find_element(:link, "Edit Groups")

      user_row = $driver.find_element_with_text('//tr', /#{@user}/, true, true)

      if user_row
        user_row.find_element(:link, "Edit Groups").click
        break
      end

      # Try the next page of users
      nextpage = $driver.find_elements(:xpath, '//a[@title="Next"]')
      if nextpage[0]
        nextpage[0].click
      else
        break
      end
    end

    # Wait for the form to load
    $driver.find_element(:id, "create_account")

    # uncheck all current groups
    $driver.find_elements(:xpath, '//input[@type="checkbox"][@checked]').each {|checkbox| checkbox.click}

    # check only the viewer group
    $driver.find_element_with_text('//tr', /repository-viewers/).find_element(:css, 'input').click

    $driver.find_element(:id, "create_account").click

    logout
  end

  it "can be modified via the Manage Access listing and then stick" do
    $driver.find_element(:link, "Sign In").click
    $driver.clear_and_send_keys([:id, 'user_username'], @user)
    $driver.clear_and_send_keys([:id, 'user_password'], @pass)
    $driver.find_element(:id, 'login').click

    select_repo(@can_manage_repo)

    assert(100) {
      $driver.ensure_no_such_element(:link, "Create")
    }
  end
end
