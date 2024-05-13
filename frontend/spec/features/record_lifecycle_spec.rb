# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Record Lifecycle', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "lifecycle_test_#{Time.now.to_i}")
    set_repo @repository

    @manager_user = create_user(@repository => ['repository-managers'])
    @archivist_user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@manager_user)
    select_repository(@repository)
  end

  it 'can suppress an Accession' do
    now = Time.now.to_i
    accession = create(:accession, title: "Accession Title #{now}")
    run_index_round

    find('#user-menu-dropdown').click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    element = find('#preference_defaults__show_suppressed_')
    element.click  if !element.checked?

    # Click on save
    find('button', text: 'Save Preferences', match: :first).click

    expect(page).to have_text 'Preferences updated'

    visit "accessions/#{accession.id}/edit"

    click_on 'Suppress'
    within '#confirmChangesModal' do
      click_on 'Suppress'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Accession Accession Title #{now} suppressed"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'

    run_index_round

    visit '/'
    visit "accessions/#{accession.id}/edit"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'
  end

  it "an archivist can't see a suppressed Accession" do
    now = Time.now.to_i
    accession = create(:accession, title: "Accession Title #{now}")
    run_index_round

    find('#user-menu-dropdown').click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    element = find('#preference_defaults__show_suppressed_')
    element.click  if !element.checked?

    # Click on save
    find('button', text: 'Save Preferences', match: :first).click

    expect(page).to have_text 'Preferences updated'

    visit "accessions/#{accession.id}/edit"

    click_on 'Suppress'
    within '#confirmChangesModal' do
      click_on 'Suppress'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Accession Accession Title #{now} suppressed"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'

    run_index_round

    visit '/'
    visit "accessions/#{accession.id}/edit"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'

    visit 'logout'

    login_user(@archivist_user)
    select_repository(@repository)

    click_on 'Browse'
    click_on 'Accessions'

    element = find('h2')
    expect(element.text).to eq('Accessions')
    expect(page).to_not have_text accession.title
    visit "accessions/#{accession.id}/edit"
    expect(page).to have_text 'Record Not Found'
    expect(page).to have_text "The record you've tried to access may no longer exist or you may not have permission to view it."
  end

  it 'can unsuppress an Accession' do
    now = Time.now.to_i
    set_repo @repository
    accession = create(:accession, title: "Accession Title #{now}")
    run_index_round

    find('#user-menu-dropdown').click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    element = find('#preference_defaults__show_suppressed_')
    element.click  if !element.checked?

    # Click on save
    find('button', text: 'Save Preferences', match: :first).click

    expect(page).to have_text 'Preferences updated'

    visit "accessions/#{accession.id}/edit"

    click_on 'Suppress'
    within '#confirmChangesModal' do
      click_on 'Suppress'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Accession Accession Title #{now} suppressed"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'

    run_index_round

    visit '/'
    visit "accessions/#{accession.id}/edit"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Accession is suppressed and cannot be edited'

    visit "accessions/#{accession.id}/edit"

    click_on 'Unsuppress'
    within '#confirmChangesModal' do
      click_on 'Unsuppress'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Accession Accession Title #{now} unsuppressed"
  end

  it 'can delete an Accession' do
    now = Time.now.to_i
    accession = create(:accession, title: "Accession Title #{now}")
    run_index_round

    visit "accessions/#{accession.id}/edit"

    click_on 'Delete'
    within '#confirmChangesModal' do
      click_on 'Delete'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Accession Accession Title #{now} deleted"

    run_index_round

    visit '/'
    click_on 'Browse'
    click_on 'Accessions'

    expect(page).to_not have_text accession.title
  end

  it 'can suppress a Digital Object' do
    now = Time.now.to_i
    set_repo @repository
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    find('#user-menu-dropdown').click
    click_on 'Default Repository Preferences'

    expect(page).to have_text "Edit these values to set preferences for all users in the current repository. These values can be overridden by a user's own preferences."

    element = find('#preference_defaults__show_suppressed_')
    element.click  if !element.checked?

    # Click on save
    find('button', text: 'Save Preferences', match: :first).click

    expect(page).to have_text 'Preferences updated'

    visit "digital_objects/#{digital_object.id}/edit"

    click_on 'Suppress'
    within '#confirmChangesModal' do
      click_on 'Suppress'
    end

    element = find('.alert.alert-success.with-hide-alert')
    expect(element).to have_text "Digital Object Digital Object Title #{now} suppressed"

    element = find('.alert.alert-info.with-hide-alert')
    expect(element).to have_text 'Digital Object is suppressed and cannot be edited'
  end
end
