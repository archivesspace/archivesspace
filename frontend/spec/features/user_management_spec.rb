# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'User management', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }

  before (:each) do
    login_user(admin_user)
  end

  xit 'can create a user account' do
    now = Time.now.to_i

    # Create admin user
    click_on 'System'
    click_on 'Manage Users'
    click_on 'Create User'
    fill_in 'Username', with: "username_#{now}"
    fill_in 'Full name', with: "Firstname Lastname #{now}"
    fill_in 'Email', with: "username_#{now}@example.com"
    fill_in 'First Name', with: "Firstname #{now}"
    fill_in 'Last Name', with: "Lastname #{now}"
    fill_in 'Phone', with: "Phone #{now}"
    fill_in 'Title', with: "Title #{now}"
    fill_in 'Department', with: "Department #{now}"
    fill_in 'Additional Contact Information', with: "Additional Contact Information #{now}"
    fill_in 'Password', with: "password"
    fill_in 'Confirm password', with: "password"
    element = find('#user_is_admin_').click

    # Click on save
    element = find('button', text: 'Create Account', match: :first)
    element.click
    expect(page).to have_text "User Created: username_#{now}"

    # Check all of the fields above
    user_row = find('tr', text: "username_#{now}")
    within user_row do
      click_on 'Edit'
    end

    expect(find('#user_username_').value).to eq "username_#{now}"
    expect(find('#user_name_').value).to eq "Firstname Lastname #{now}"
    expect(find('#user_email_').value).to eq "username_#{now}@example.com"
    expect(find('#user_first_name_').value).to eq "Firstname #{now}"
    expect(find('#user_last_name_').value).to eq "Lastname #{now}"
    expect(find('#user_telephone_').value).to eq "Phone #{now}"
    expect(find('#user_title_').value).to eq "Title #{now}"
    expect(find('#user_department_').value).to eq "Department #{now}"
    expect(find('#user_additional_contact_').value).to eq "Additional Contact Information #{now}"
  end

  xit "doesn't delete user information after the new user logins" do
    now = Time.now.to_i

    # Create admin user
    click_on 'System'
    click_on 'Manage Users'
    click_on 'Create User'
    fill_in 'Username', with: "username_#{now}"
    fill_in 'Full name', with: "Firstname Lastname #{now}"
    fill_in 'Password', with: "password"
    fill_in 'Confirm password', with: "password"
    element = find('#user_is_admin_').click

    # Click on save
    element = find('button', text: 'Create Account', match: :first)
    element.click
    expect(page).to have_text "User Created: username_#{now}"

    run_index_round

    # Logout admin user
    element = find('#user-menu-dropdown')
    element.click
    click_on 'Logout'
    expect(page).to have_text 'Please Sign In'

    # Login with the previously created admin user
    within "form.login" do
      fill_in "username", with: "username_#{now}"
      fill_in "password", with: 'password'

      click_button "Sign In"
    end

    element = find('span.user-label')
    expect(element).to have_text "username_#{now}"

    # Logout user
    element = find('#user-menu-dropdown')
    element.click
    click_on 'Logout'
    expect(page).to have_text 'Please Sign In'

    login_user(admin_user)

    click_on 'System'
    click_on 'Manage Users'

    element = find("#edit_username_#{now}")
    element.click

    element = find('#user_username_')
    expect(element.value).to eq "username_#{now}"

    element = find('#user_name_')
    expect(element.value).to eq "Firstname Lastname #{now}"

    element = find('#user_is_admin_')
    expect(element.value).to eq '1'
  end

  xit "doesn't allow another user to edit the global admin or a system account" do
    # TODO this example was ignored to get the Softserv updates merged into master;
    # the cause for this failing remotely but not locally is as yet unknown
    now = Time.now.to_i

    # Create admin user
    click_on 'System'
    click_on 'Manage Users'
    click_on 'Create User'
    fill_in 'Username', with: "username_#{now}"
    fill_in 'Full name', with: "Firstname Lastname #{now}"
    fill_in 'Password', with: "password"
    fill_in 'Confirm password', with: "password"
    element = find('#user_is_admin_').click

    # Click on save
    element = find('button', text: 'Create Account', match: :first)
    element.click
    expect(page).to have_text "User Created: username_#{now}"

    run_index_round

    # Logout admin user
    element = find('#user-menu-dropdown')
    element.click
    click_on 'Logout'
    expect(page).to have_text 'Please Sign In'

    # Login with the previously created admin user
    within "form.login" do
      fill_in "username", with: "username_#{now}"
      fill_in "password", with: 'password'

      click_button "Sign In"
    end

    element = find('span.user-label')
    expect(element).to have_text "username_#{now}"

    visit '/users'
    expect(page).to have_text 'Users'

    # Find admin entry on users table
    element = all('table tbody tr td')
    expect(element[0]).to have_text 'admin'
    within element[7] do
      click_on 'Edit'
    end

    expect(page).to have_text 'Access denied. Login as the admin user to perform this action.'
  end

  xit "doesn't allow you to edit the user short names" do
    visit '/users'
    expect(page).to have_text 'Users'

    # Find admin entry on users table
    element = all('table tbody tr td')
    expect(element[0]).to have_text 'admin'
    within element[7] do
      click_on 'Edit'
    end

    # WARNING: The backend does not provide any protection against changing the admin username
    element = find('#user_username_')
    expect(page).to have_field('user_username_', readonly: true)
  end

  xit "allows user to edit their own account" do
    now = Time.now.to_i

    # Create admin user
    click_on 'System'
    click_on 'Manage Users'
    click_on 'Create User'
    fill_in 'Username', with: "username_#{now}"
    fill_in 'Full name', with: "Firstname Lastname #{now}"
    fill_in 'Password', with: "password"
    fill_in 'Confirm password', with: "password"
    element = find('#user_is_admin_').click

    # Click on save
    element = find('button', text: 'Create Account', match: :first)
    element.click
    expect(page).to have_text "User Created: username_#{now}"

    run_index_round

    # Logout admin user
    element = find('#user-menu-dropdown')
    element.click
    click_on 'Logout'
    expect(page).to have_text 'Please Sign In'

    # Login with the previously created admin user
    within "form.login" do
      fill_in "username", with: "username_#{now}"
      fill_in "password", with: 'password'

      click_button "Sign In"
    end

    element = find('span.user-label')
    expect(element).to have_text "username_#{now}"

    visit 'users/edit_self'

    fill_in 'Full name', with: "Updated Firstname Lastname #{now}"
    fill_in 'Password', with: "updated_password"
    fill_in 'Confirm password', with: "updated_password"

    # Click on update account
    element = find('button', text: 'Update Account', match: :first)
    element.click

    # Logout
    element = find('#user-menu-dropdown')
    element.click
    click_on 'Logout'
    expect(page).to have_text 'Please Sign In'

    # Login with the udpated admin user using the previous password
    within "form.login" do
      fill_in "username", with: "username_#{now}"
      fill_in "password", with: 'password'

      click_button "Sign In"
    end

    expect(page).to have_text 'Login attempt failed'

    # Login with the udpated admin user using the updated password
    within "form.login" do
      fill_in "username", with: "username_#{now}"
      fill_in "password", with: 'updated_password'

      click_button "Sign In"
    end

    expect(page).to have_text 'Welcome to ArchivesSpace'

    element = find('span.user-label')
    expect(element).to have_text "username_#{now}"
  end
end
