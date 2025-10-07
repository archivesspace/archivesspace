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
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:allow_mixed_content_title_fields) { true }
    login_admin
    select_repository(@repo)
  end

  it 'will let an admin change default values' do
    visit('/preferences/0/edit?global=true')
    check('preference[defaults][default_values]')
    click_button('Save')
    expect(page).to have_checked_field('preference[defaults][default_values]')
    expect(page).to have_content('Preferences updated')

    visit '/accessions'
    click_link('Edit Default Values')
    wait_for_ajax
    expect(page).to have_css("#accession_title_", visible: false)
    execute_script("$('#accession_title_').data('CodeMirror').setValue('DEFAULT TITLE')")
    click_on('Save')
    expect(page).to have_content('Defaults Updated')

    visit('/accessions/new')
    expect(page).to have_content('DEFAULT TITLE')

    visit('/preferences/0/edit?global=true')
    uncheck('preference[defaults][default_values]')
    click_button('Save')
    expect(page).to have_unchecked_field('preference[defaults][default_values]')
    expect(page).to have_content('Preferences updated')

    visit('/accessions/new')
    expect(page).not_to have_content('DEFAULT TITLE')
  end

  it "won't let a regular archivist edit default accession values" do
    visit('/logout')
    login_user(@archivist_user)
    visit '/accessions'
    expect(page).not_to have_content('Edit Default Values')
  end

  it 'verifies container profile extent dimension defaults behavior' do
    visit('/preferences/0/edit?global=true')
    check('preference[defaults][default_values]')
    click_button('Save')
    expect(page).to have_checked_field('preference[defaults][default_values]')
    expect(page).to have_content('Preferences updated')

    # First verify that without any defaults set, new container profiles default to "Height"
    visit('/container_profiles/new')
    expect(page).to have_select('container_profile_extent_dimension_', selected: 'Height')

    # Now set defaults to "Width" (addressing the Jira issue requirement)
    visit '/container_profiles'
    click_link('Edit Default Values')
    wait_for_ajax

    fill_in 'container_profile_name_', with: 'DEFAULT BOX'
    select 'Width', from: 'container_profile_extent_dimension_'
    fill_in 'container_profile_depth_', with: '12'
    fill_in 'container_profile_height_', with: '15'
    fill_in 'container_profile_width_', with: '10'
    select 'Inches', from: 'container_profile_dimension_units_'

    click_button('Save Container Profile', match: :first)
    expect(page).to have_content('Defaults Updated')    # Verify defaults are applied with "Width" selected
    visit('/container_profiles/new')
    expect(page).to have_field('container_profile_name_', with: 'DEFAULT BOX')
    expect(page).to have_select('container_profile_extent_dimension_', selected: 'Width')
    expect(page).to have_field('container_profile_depth_', with: '12')
    expect(page).to have_field('container_profile_height_', with: '15')
    expect(page).to have_field('container_profile_width_', with: '10')
    expect(page).to have_select('container_profile_dimension_units_', selected: 'Inches')

    # Now test changing defaults to "Height"
    visit '/container_profiles'
    click_link('Edit Default Values')
    wait_for_ajax

    select 'Height', from: 'container_profile_extent_dimension_'
    click_button('Save Container Profile', match: :first)
    expect(page).to have_content('Defaults Updated')

    # Verify defaults now use "Height"
    visit('/container_profiles/new')
    expect(page).to have_field('container_profile_name_', with: 'DEFAULT BOX')
    expect(page).to have_select('container_profile_extent_dimension_', selected: 'Height')
    expect(page).to have_field('container_profile_depth_', with: '12')
    expect(page).to have_field('container_profile_height_', with: '15')
    expect(page).to have_field('container_profile_width_', with: '10')
    expect(page).to have_select('container_profile_dimension_units_', selected: 'Inches')
  end
end
