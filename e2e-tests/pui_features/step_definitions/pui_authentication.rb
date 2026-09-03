# frozen_string_literal: true

Given 'a user without PUI viewer permission exists' do
  uuid = SecureRandom.uuid
  @no_pui_username = "no-pui-user-#{uuid}"

  login_admin

  visit "#{STAFF_URL}/users/new"

  fill_in 'user_username_', with: @no_pui_username
  fill_in 'user_name_', with: @no_pui_username
  fill_in 'user_password_', with: @no_pui_username
  fill_in 'user_confirm_password_', with: @no_pui_username

  find('#create_account').click

  expect(page).to have_text "User Created: #{@no_pui_username}"

  visit "#{STAFF_URL}/logout"
end

When(/^(?:an anonymous visitor visits|the user visits) the PUI$/) do
  visit PUBLIC_URL
end

When 'the user logs out of the PUI' do
  click_link 'pui-logout'
end

When 'an administrator logs in directly on the PUI' do
  visit PUBLIC_URL

  fill_in 'user_name', with: 'admin'
  fill_in 'password', with: 'admin'
  click_on 'Sign In'
end

When 'that user logs in directly on the PUI' do
  visit PUBLIC_URL

  fill_in 'user_name', with: @no_pui_username
  fill_in 'password', with: @no_pui_username
  click_on 'Sign In'
end

Then 'the welcome page is displayed' do
  expect(page).to have_text 'Welcome to ArchivesSpace'
end

Then 'the login page is displayed' do
  expect(page).to have_text 'Please Sign In'
end

Then 'the user is signed in to the PUI as {string}' do |username|
  expect(page).not_to have_text 'Please Sign In'

  within '.user-container' do
    expect(page).to have_text username
  end
end

Then 'the PUI permission denied message is displayed' do
  expect(page).to have_text 'does not have permission to view the PUI'
end
