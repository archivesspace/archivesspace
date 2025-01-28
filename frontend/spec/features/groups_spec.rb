# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Groups', js: true do
  before(:all) do
    @repository_to_manage = create(:repo, repo_code: "groups_test_manage_#{Time.now.to_i}")
    @repository_to_view = create(:repo, repo_code: "groups_test_view_#{Time.now.to_i}")
    @user = create_user
  end

  it 'can assign a user to the archivist group' do
    login_admin
    select_repository @repository_to_manage

    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'

    element = find(:xpath, "//tr[contains(., 'repository-archivists')]")
    within element do
      click_on 'Edit'
    end

    fill_in 'new-member', with: @user.username
    find('#add-new-member').click

    element = find('#group_member_usernames_')
    expect(element).to have_text @user.username

    click_on 'Save'

    element = find(:xpath, "//tr[contains(., 'repository-archivists')]")
    within element do
      click_on 'Edit'
    end

    element = find('#group_member_usernames_')
    expect(element).to have_text @user.username

    visit '/logout'
  end

  it 'can assign the test user to the viewers group of the first repository' do
    login_admin
    select_repository @repository_to_view
    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'

    element = find(:xpath, "//tr[contains(., 'repository-viewers')]")
    within element do
      click_on 'Edit'
    end

    fill_in 'new-member', with: @user.username
    find('#add-new-member').click

    element = find('#group_member_usernames_')
    expect(element).to have_text @user.username

    click_on 'Save'

    element = find(:xpath, "//tr[contains(., 'repository-viewers')]")
    within element do
      click_on 'Edit'
    end

    element = find('#group_member_usernames_')
    expect(element).to have_text @user.username

    visit '/logout'
  end

  it 'reports errors when attempting to create a Group with missing data' do
    login_admin
    select_repository @repository_to_view

    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'
    click_on 'Create Group'

    # Click on save
    find('button', text: 'Create Group', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Group code - Property is required but was missing\nDescription - Property is required but was missing"
  end

  it 'can create a new Group' do
    now = Time.now.to_i
    login_admin
    select_repository @repository_to_view
    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'
    click_on 'Create Group'

    fill_in 'group_group_code_', with: "Group Code #{now}"
    fill_in 'group_description_', with: "Group Description #{now}"
    find('#view_repository').click

    find('button', text: 'Create Group', match: :first).click
    expect(page).to have_text "Group Code #{now}"

    visit '/logout'
  end

  it 'reports errors when attempting to update a Group with missing data' do
    now = Time.now.to_i
    login_admin
    select_repository @repository_to_view
    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'
    click_on 'Create Group'

    fill_in 'group_group_code_', with: "Group Code #{now}"
    fill_in 'group_description_', with: "Group Description #{now}"
    find('#view_repository').click

    # Click on save
    find('button', text: 'Create Group', match: :first).click
    expect(page).to have_text "Group Code #{now}"
    element = find(:xpath, "//tr[contains(., 'Group Code #{now}')]")
    within element do
      click_on 'Edit'
    end

    fill_in 'group_description_', with: ''

    find('button', text: 'Save', match: :first).click
    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Description - Property is required but was missing"

    visit '/logout'
  end

  it 'can edit a Group' do
    # TODO: passes locally but not remotely
    now = Time.now.to_i
    login_admin
    select_repository @repository_to_view
    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage Groups'
    click_on 'Create Group'

    fill_in 'group_group_code_', with: "Group Code #{now}"
    fill_in 'group_description_', with: "Group Description #{now}"
    find('#view_repository').click

    find('button', text: 'Create Group', match: :first).click
    expect(page).to have_text "Group Code #{now}"
    element = find(:xpath, "//tr[contains(., 'Group Code #{now}')]")
    within element do
      click_on 'Edit'
    end

    fill_in 'group_description_', with: "Group Description Updated #{now}"

    find('button', text: 'Save', match: :first).click

    expect(page).to have_text "Group Description Updated #{now}"

    visit '/logout'
  end

  it 'can get a list of usernames matching a string' do
    login_admin
    visit "/users/complete?query=#{Addressable::URI.escape(@user.username)}"
    expect(page).to have_text @user.username

    visit '/logout'
  end

  it 'can log out of the admin account' do
    login_admin
    visit 'logout'
    expect(page).to have_css '#login-form-wrapper'
  end

  it 'can log in with the user just created' do
    visit '/'
    fill_in 'user_username', with: @user.username
    fill_in 'user_password', with: @user.password
    click_on 'Sign In'

    element = find('span.user-label')
    expect(element).to have_text @user.username

    visit '/logout'
  end

  it 'can select the second repository and find the create link' do
    login_admin
    select_repository @repository_to_manage

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq "The Repository #{@repository_to_manage.repo_code} is now active"

    expect(page).to have_css('button', text: 'Create')

    visit '/logout'
  end

  it "can modify the user's groups for a repository via the Manage Access listing and hides create from user" do
    login_admin
    select_repository @repository_to_manage

    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage User Access'

    element = find(:xpath, "//tr[contains(., '#{@user.username}')]")
    within element do
      click_on 'Edit Groups'
    end

    # Uncheck all current groups
    elements = all('#form_user input')
    elements.each do |element|
      element.click if element.checked?
    end

    element = find(:xpath, "//tr[contains(., 'repository-viewers')]")
    input = element.find('input')
    input.click

    click_on 'Update Account'

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'User Saved'

    visit 'logout'
    login_user(@user)
    select_repository @repository_to_manage

    expect(page).to_not have_css('a', text: 'Create')

    visit '/logout'
  end

  it 'cannot modify the user groups via Manage Access if the user is an admin' do
    now = Time.now.to_i
    login_admin
    select_repository @repository_to_manage

    find('.repo-container .btn.dropdown-toggle').click
    click_on 'Manage User Access'

    element = find(:xpath, "//tr[contains(., 'admin')]")
    within element do
      expect(element).to have_css 'a.disabled', text: 'Edit Groups'
    end

    visit '/logout'
  end
end
