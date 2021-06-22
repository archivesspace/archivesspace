# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Groups' do
  before(:all) do
    @repo_to_manage = create(:repo, repo_code: "groups_test_manage_#{Time.now.to_i}")
    @repo_to_view = create(:repo, repo_code: "groups_test_view_#{Time.now.to_i}")

    @user = create_user

    # wait for notification to fire (which can take up to 5 seconds)
    @driver = Driver.get.login($admin)
  end

  after(:all) do
    @driver ? @driver.quit : next
  end

  it 'can assign a user to the archivist group' do
    @driver.select_repo(@repo_to_manage)

    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Manage Groups').click

    row = @driver.find_element_with_text('//tr', /repository-archivists/)
    edit_link = row.find_element(:link, 'Edit')
    @driver.click_and_wait_until_element_gone(edit_link)

    @driver.clear_and_send_keys([:id, 'new-member'], @user.username)
    @driver.find_element(:id, 'add-new-member').click
    @driver.click_and_wait_until_gone(css: 'button[type="submit"]')
  end

  it 'can assign the test user to the viewers group of the first repository' do
    @driver.select_repo(@repo_to_view)
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Manage Groups').click

    row = @driver.find_element_with_text('//tr', /repository-viewers/)
    row.find_element(:css, '.btn').click

    @driver.clear_and_send_keys([:id, 'new-member'], @user.username)
    @driver.find_element(:id, 'add-new-member').click
    @driver.click_and_wait_until_gone(css: 'button[type="submit"]')
  end

  it 'reports errors when attempting to create a Group with missing data' do
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Manage Groups').click
    @driver.find_element(:link, 'Create Group').click
    @driver.find_element(css: "form#new_group button[type='submit']").click
    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Group code - Property is required but was missing/)
    end.not_to raise_error
    @driver.click_and_wait_until_gone(:link, 'Cancel')
  end

  it 'can create a new Group' do
    @driver.find_element(:link, 'Create Group').click
    @driver.clear_and_send_keys([:id, 'group_group_code_'], 'goo')
    @driver.clear_and_send_keys([:id, 'group_description_'], 'Goo group to group goo')
    @driver.find_element(:id, 'view_repository').click
    @driver.click_and_wait_until_gone(css: "form#new_group button[type='submit']")
    expect do
      @driver.find_element_with_text('//tr', /goo/)
    end.not_to raise_error
  end

  it 'reports errors when attempting to update a Group with missing data' do
    @driver.find_element_with_text('//tr', /goo/).find_element(:link, 'Edit').click
    @driver.clear_and_send_keys([:id, 'group_description_'], '')
    @driver.find_element(css: "form#new_group button[type='submit']").click
    expect do
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Description - Property is required but was missing/)
    end.not_to raise_error
    @driver.click_and_wait_until_gone(:link, 'Cancel')
  end

  it 'can edit a Group' do
    row = @driver.find_element_with_text('//tr', /goo/)
    edit_link = row.find_element(:link, 'Edit')
    @driver.click_and_wait_until_element_gone(edit_link)
    @driver.clear_and_send_keys([:id, 'group_description_'], 'Group to gather goo')
    @driver.click_and_wait_until_gone(css: "form#new_group button[type='submit']")
    expect do
      @driver.find_element_with_text('//tr', /Group to gather goo/)
    end.not_to raise_error
  end

  it 'can get a list of usernames matching a string' do
    @driver.get(URI.join($frontend, "/users/complete?query=#{URI.escape(@user.username)}"))
    expect(@driver.page_source).to match(/#{@user.username}/)
    @driver.get(URI.join($frontend))
  end

  it 'can log out of the admin account' do
    @driver.logout
  end

  it 'can log in with the user just created' do
    @driver.clear_and_send_keys([:id, 'user_username'], @user.username)
    @driver.clear_and_send_keys([:id, 'user_password'], @user.password)
    @driver.click_and_wait_until_gone(:id, 'login')

    assert(5) { expect(@driver.find_element(css: 'span.user-label').text).to match(/#{@user.username}/) }
  end

  it 'can select the second repository and find the create link' do
    @driver.select_repo(@repo_to_manage)

    # Wait until it's selected
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /#{@repo_to_manage.repo_code}/)
    @driver.find_element(:link, 'Create')
  end

  it "can modify the user's groups for a repository via the Manage Access listing" do
    @driver.logout.login_to_repo($admin, @repo_to_manage)

    # change @can_manage_repo to a view only
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Manage User Access').click

    loop do
      # Wait for the table to load
      @driver.find_element(:link, 'Edit Groups')

      user_row = @driver.find_element_with_text('//tr', /#{@user.username}/, true, true)

      if user_row
        @driver.click_and_wait_until_element_gone(user_row.find_element(:link, 'Edit Groups'))
        break
      end

      # Try the next page of users
      nextpage = @driver.find_elements(:xpath, '//a[@title="Next"]')
      if nextpage[0]
        nextpage[0].click
      else
        break
      end
    end

    # Wait for the form to load
    @driver.find_element(:id, 'create_account')

    # uncheck all current groups
    @driver.find_elements(:xpath, '//input[@type="checkbox"][@checked]').each { |checkbox| checkbox.click }

    # check only the viewer group
    @driver.find_element_with_text('//tr', /repository-viewers/).find_element(:css, 'input').click

    @driver.click_and_wait_until_gone(:id, 'create_account')

    @driver.logout
  end

  it 'can be modified via the Manage Access listing and then stick' do
    @driver.login_to_repo(@user, @repo_to_manage)

    assert(100) do
      @driver.ensure_no_such_element(:link, 'Create')
    end
  end

  it 'cannot modify the user groups via Manage Access if the user is an admin' do
    @driver.logout.login_to_repo($admin, @repo_to_manage)

    # change @can_manage_repo to a view only
    @driver.find_element(:css, '.repo-container .btn.dropdown-toggle').click
    @driver.wait_for_dropdown
    @driver.find_element(:link, 'Manage User Access').click

    loop do
      # Wait for the table to load
      @driver.find_element(:link, 'Edit Groups')

      # assume (for now at least) admin is always on the first page
      admin_row = @driver.find_element_with_text('//tr', /admin/, true, true)
      if admin_row && !admin_row.nil?
        expect do
          admin_row.find_element(:css, 'a.disabled')
        end.not_to raise_error
        break
      elsif admin_row.nil?
        i = 2
        while admin_row.nil?
          @driver.find_element(:link, i.to_s).click
          admin_row = @driver.find_element_with_text('//tr', /admin/, true, true)
          expect do
            admin_row.find_element(:css, 'a.disabled')
          end.not_to raise_error
          i += 1
        end
        break
      end
    end
  end
end
