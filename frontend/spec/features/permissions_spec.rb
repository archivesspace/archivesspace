# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Permissions', js: true do
  context 'Resources and archival objects' do
    it 'allows archivists to edit major record types by default' do
      repository = create(:repo, repo_code: "permissions_test_#{Time.now.to_i}")
      set_repo(repository)
      archivist = create_user(repository => ['repository-archivists'])
      login_user(archivist)

      click_on 'Create'
      click_on 'Accession'
      element = find('h2')
      expect(element.text).to eq('New Accession Accession')

      click_on 'Create'
      click_on 'Resource'
      element = find('h2')
      expect(element.text).to eq('New Resource Resource')

      click_on 'Create'
      click_on 'Digital Object'
      element = find('h2')
      expect(element.text).to eq('New Digital Object Digital Object')
    end

    it 'supports denying permission to edit Resources' do
      repository = create(:repo, repo_code: "permissions_test_#{Time.now.to_i}")
      set_repo(repository)
      archivist = create_user(repository => ['repository-archivists'])

      resource = create(:resource, title: "Resource #{Time.now.to_i}")
      run_index_round

      login_admin
      select_repository(repository)

      find('.repo-container .btn.dropdown-toggle').click
      click_on 'Manage Groups'

      element = find('h2')
      expect(element.text).to eq('Groups')

      element = find(:xpath, "//tr[contains(., 'repository-archivists')]")
      within element do
        click_on 'Edit'
      end

      element = find('#update_resource_record')
      element.click

      expect(element.checked?).to eq false

      element = find('button', text: 'Save', match: :first)
      element.click

      visit 'logout'
      login_user(archivist)
      select_repository(repository)

      click_on 'Create'
      expect(page).to_not have_css('a', text: 'Resouce')

      visit 'resources/new'
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element.text).to eq "Unable to Access Page\nThe page you've tried to access may no longer exist or you may not have permission to view it."

      visit '/'
      visit "resources/#{resource.id}/edit"
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element.text).to eq "Unable to Access Page\nThe page you've tried to access may no longer exist or you may not have permission to view it."
    end
  end

  context 'Agents' do
    describe 'non full record, or lightmode, permissions' do
      it 'successfully removes the appropriate sections from the document layout' do
        login_admin
        visit '/users/new'
        fill_in 'Username', with: 'test_user'
        fill_in 'Full name', with: 'Test User'
        fill_in 'Password', with: 'password'
        fill_in 'Confirm password', with: 'password'
        submit = find('#create_account')
        submit.click
        expect(page).to have_text 'User Created: test_user'

        visit '/groups/new'
        fill_in 'Group code', with: 'agents_light_mode'
        fill_in 'Description', with: 'Agents Light Mode'
        fill_in 'Username', with: 'test_user'
        submit = find('#add-new-member')
        submit.click

        check 'create/update/delete agents (system-wide)'
        check 'view_repository'
        click_on 'Create Group'

        element = find('#user-menu-dropdown')
        element.click
        click_on 'Become User'

        fill_in 'Username', with: 'test_user'
        click_on 'Become User'
        expect(page).to have_text 'Successfully switched users'

        visit '/agents/agent_person/new'
        expect(page).to have_css('section.lightmode_toggle.d-none', count: 14, visible: false)
      end
    end
  end
end
