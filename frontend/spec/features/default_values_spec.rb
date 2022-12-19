# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Default Form Values', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "default_values_test_#{Time.now.to_i}", publish: true)
    @archivist_user = create_user(@repo => ['repository-archivists'])
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  it 'will let an admin change default values' do
    visit('/preferences/0/edit?repo=true')
    check('preference[defaults][default_values]')
    click_button('Save')
    expect(page).to have_checked_field('preference[defaults][default_values]')
    expect(page).to have_content('Preferences updated')
  end

  xit 'will let an admin create default accession values' do
    visit '/accessions'

    # TODO: this currently triggers a "Record Not Found" error page... bug?
    click_link('Edit Default Values')
    expect(page).to have_field('accession[title]')

    fill_in('accession[title]', with: 'DEFAULT TITLE')
    click_on('Save')
    expect(page).to have_content('Defaults Updated')

    visit('/accessions/new')
    expect(find('accession[title]')).to have_content('DEFAULT_TITLE')
  end

  it "won't let a regular archivist edit default accession values" do
    visit('/logout')
    login_user(@archivist_user)
    visit '/accessions'
    expect(page).not_to have_content('Edit Default Values')
  end
end
