# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Default Form Values', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "default_values_test_#{Time.now.to_i}")
    @archivist_user = create_user(@repo => ['repository-archivists'])

    login_admin

    visit('/preferences/0/edit?global=true')
    check('preference[defaults][default_values]')
    click_button('Save')

    expect(page).to have_checked_field('preference[defaults][default_values]')
    expect(page).to have_content('Preferences updated')
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  it 'will let an admin create default accession values' do
    visit '/accessions'

    click_link('Edit Default Values')
    expect(page).to have_field('accession[title]')

    fill_in('accession[title]', with: 'DEFAULT TITLE')
    click_on('Save')
    expect(page).to have_content('Defaults Updated')

    visit('/accessions/new')
    expect(page).to have_content('DEFAULT TITLE')
  end

  it "won't let a regular archivist edit default accession values" do
    visit('/logout')
    login_user(@archivist_user)
    visit '/accessions'
    expect(page).not_to have_content('Edit Default Values')
  end
end
