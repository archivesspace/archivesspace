# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'System Information', js: true do
  let(:admin_user) { BackendClientMethods::ASpaceUser.new('admin', 'admin') }
  let!(:repository) { create(:repo, repo_code: "system_information_#{Time.now.to_i}") }
  let(:archivist_user) { create_user(repository => ['repository-archivists']) }

  it 'should not let an archivist user see this' do
    login_user(archivist_user)
    select_repository(repository)

    click_on 'System'
    expect(page).to_not have_text 'System Information'

    visit '/system_info'

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Unable to Access Page\nThe page you've tried to access may no longer exist or you may not have permission to view it."
  end

  it 'should let the admin see this' do
    login_user(admin_user)
    select_repository(repository)

    click_on 'System'
    click_on 'System Information'

    expect(page).to have_text 'Frontend System Information'
    expect(page).to have_text 'VERSION'
    expect(page).to have_text 'APPCONFIG'
    expect(page).to have_text 'MEMORY'
    expect(page).to have_text 'CPU_COUNT'
  end

  it 'should not let a user with administer_system perrmissions see this if allow_other_admins_access_to_system_info is set to false' do
    AppConfig[:allow_other_admins_access_to_system_info] = false

    user_with_administer_system = create_user(repository => ['repository-archivists'])

    login_user(admin_user)
    select_repository(repository)

    click_on 'System'
    click_on 'Manage Users'

    element = find('tr', text: user_with_administer_system.username)
    within element do
      click_on 'Edit'
    end

    expect(page).to have_text 'Edit Account'
    find('#user_is_admin_').click
    find('button', text: 'Update Account', match: :first).click

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'User Saved'

    visit 'logout'

    login_user(user_with_administer_system)
    select_repository(repository)

    click_on 'System'
    click_on 'System Information'

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Unable to Access Page\nThe page you've tried to access may no longer exist or you may not have permission to view it."
  end

  it 'should let a user with administer_system perrmissions see this if allow_other_admins_access_to_system_info is set to true' do
    AppConfig[:allow_other_admins_access_to_system_info] = true

    user_with_administer_system = create_user(repository => ['repository-archivists'])

    login_user(admin_user)
    select_repository(repository)

    click_on 'System'
    click_on 'Manage Users'

    element = find('tr', text: user_with_administer_system.username)
    within element do
      click_on 'Edit'
    end

    expect(page).to have_text 'Edit Account'
    find('#user_is_admin_').click
    find('button', text: 'Update Account', match: :first).click

    element = find('.alert.alert-success.with-hide-alert')
    expect(element.text).to eq 'User Saved'

    visit 'logout'

    login_user(user_with_administer_system)
    select_repository(repository)

    click_on 'System'
    click_on 'System Information'

    expect(page).to have_text 'Frontend System Information'
    expect(page).to have_text 'VERSION'
    expect(page).to have_text 'APPCONFIG'
    expect(page).to have_text 'MEMORY'
    expect(page).to have_text 'CPU_COUNT'
  end
end
