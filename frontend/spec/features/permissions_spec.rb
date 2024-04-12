# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Resources and archival objects', js: true do
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
