# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Users and Authentication', js: true do
  it 'fails logins with invalid credentials' do
    now = Time.now.to_i

    visit '/'
    expect(page).to have_text 'Please Sign In'

    within "form.login" do
      fill_in "username", with: "username #{now}"
      fill_in "password", with: "password"

      click_button "Sign In"
    end

    expect(page).to have_text 'Login attempt failed'
  end

  it 'fails login when user is inactive' do
    user_inactive = create_user({}, false)

    visit '/'
    expect(page).to have_text 'Please Sign In'

    within "form.login" do
      fill_in "username", with: user_inactive.username
      fill_in "password", with: user_inactive.password

      click_button "Sign In"
    end

    expect(page).to have_text 'Login attempt failed'
  end

  it 'can register a new user and check that user has no repositories' do
    now = Time.now.to_i

    visit '/'
    expect(page).to have_text 'Please Sign In'

    click_on 'Register now'
    fill_in 'Username', with: "username #{now}"
    fill_in 'Full name', with: "Firstname Lastname #{now}"
    fill_in 'Password', with: 'password'
    fill_in 'Confirm password', with: 'password'

    # Click on create account
    element = find('button', text: 'Create Account', match: :first)
    element.click

    element = find('.user-label')
    expect(element).to have_text "username #{now}"

    # User has no repositories
    expect(page).to have_text 'You do not have access to any Repositories.'
    expect(page).to have_text 'Please contact your System Administrator to request access.'
    expect(page).not_to have_link('Select Repository')
  end

  it 'allows the admin user to become a different user' do
    user = create_user
    admin_user = BackendClientMethods::ASpaceUser.new('admin', 'admin')

    visit '/'
    expect(page).to have_text 'Please Sign In'

    within "form.login" do
      fill_in "username", with: admin_user.username
      fill_in "password", with: admin_user.password

      click_button "Sign In"
    end

    expect(page).to have_text 'Welcome to ArchivesSpace'
    element = find('.user-container')
    expect(element).to have_text 'admin'

    find('#user-menu-dropdown').click
    click_on 'Become User'
    fill_in 'select-user', with: user.username
    click_on 'Become User'

    expect(page).to have_text 'Successfully switched users'
  end

  it 'prevents any user from becoming the global admin' do
    admin_user = BackendClientMethods::ASpaceUser.new('admin', 'admin')

    visit '/'
    expect(page).to have_text 'Please Sign In'

    within "form.login" do
      fill_in "username", with: admin_user.username
      fill_in "password", with: admin_user.password

      click_button "Sign In"
    end

    expect(page).to have_text 'Welcome to ArchivesSpace'
    element = find('.user-container')
    expect(element).to have_text 'admin'

    find('#user-menu-dropdown').click
    click_on 'Become User'
    fill_in 'select-user', with: 'admin'
    click_on 'Become User'

    expect(page).to have_text 'Failed to switch to the specified user'
  end

  it 'can activate users' do
    user = create_user({}, false)
    admin_user = BackendClientMethods::ASpaceUser.new('admin', 'admin')

    visit '/'
    expect(page).to have_text 'Please Sign In'

    within "form.login" do
      fill_in "username", with: admin_user.username
      fill_in "password", with: admin_user.password

      click_button "Sign In"
    end

    expect(page).to have_text 'Welcome to ArchivesSpace'
    element = find('.user-container')
    expect(element).to have_text 'admin'

    visit '/users'

    expect(page).to have_current_path('/users')
    expect(page).to have_text 'Users'

    # Activate the user
    user_row = find('tr', text: user.username)
    within user_row do
      click_on 'Activate'
    end
    expect(page).to have_text 'User activated'

    # Deactivate the user
    user_row = find('tr', text: user.username)
    expect(user_row).to have_text 'Deactivate'
    within user_row do
      click_on 'Deactivate'
    end
    expect(page).to have_text 'User deactivated'

    user_row = find('tr', text: user.username)
    expect(user_row).to have_text 'Activate'
  end
end
