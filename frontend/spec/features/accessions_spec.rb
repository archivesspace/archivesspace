# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Accessions', js: true do
  let(:accession_title) { 'Test accession title' }

  before(:all) do
    @repo = create(:repo, repo_code: "accession_test_#{Time.now.to_i}")
    set_repo @repo

    @accession = create(:accession)
    @other_accession = create(:accession, title: 'Link to me')

    @user = create_user(@repo => ['repository-archivists'])

    run_all_indexers
  end

  before(:each) do
    login_user(@user)
    select_repository(@repo)
  end

  it 'can create an accession' do
    click_on('Create')
    click_on('Accession')
    fill_in('Title', with: accession_title)
    fill_in("Identifier", with: "test_#{Time.now}")
    fill_in("Accession Date", with: "2012-01-01")
    fill_in("Content Description", with: "Lots of paperclips")
    fill_in("Condition Description", with: "pristine")

    # Αdd a date
    click_on('Add Date')
    select 'Digitized', from: 'Label'
    select 'Single', from: 'Type'
    fill_in("Expression", with: "The day before yesterday.")

    # Add a rights subrecord
    click_on('Add Rights Statement')
    select 'Copyright', from: 'Rights Type'
    select 'Copyrighted', from: 'Status'
    fill_in("Start Date", with: "2012-01-01")
    element = find('#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)', match: :first)

    element = find(:xpath, '//*[@id="accession_rights_statements__0__jurisdiction_"]')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)
    find_by_id('accession_rights_statements__0__start_date_').set('2012-01-01')

    # Αdd an external document to the rights statement
    within('#accession_rights_statements_') do
      find('button', :text => 'Add External Document', match: :first).click
      fill_in("Title", with: "Agreement")
      fill_in("Location", with: "http://locationof.agreement.com")

      element = find(:xpath, '//*[@id="accession_rights_statements__0__external_documents__0__identifier_type_"]')
      element.click
      element.send_keys('Trove')
      element.send_keys :tab
    end

    # Save
    find("form#accession_form button[type='submit']", match: :first).click
    expect(page).to have_text "Accession #{accession_title} created"
    expect(page).to have_field('accession_title_', with: accession_title)
  end

  it 'can update an accession' do
    click_on('Browse')
    click_on('Accessions')
    first(:link, 'Edit').click
    fill_in('Title', with: accession_title)
    click_on('Save')
    expect(page).to have_text "Accession #{accession_title} updated"
    expect(page).to have_field('accession_title_', with: accession_title)
  end

  it 'can spawn an accession from an existing accession' do
    click_on('Create')
    click_on('Accession')
    fill_in('Title', with: accession_title)
    fill_in("Identifier", with: "test_#{Time.now}")
    fill_in("Accession Date", with: "2012-01-01")
    fill_in("Content Description", with: "Lots of paperclips")
    fill_in("Condition Description", with: "pristine")

    # Αdd a date
    click_on('Add Date')
    select 'Digitized', from: 'Label'
    select 'Single', from: 'Type'
    fill_in("Expression", with: "The day before yesterday.")

    # Add a rights subrecord
    click_on('Add Rights Statement')
    select 'Copyright', from: 'Rights Type'
    select 'Copyrighted', from: 'Status'
    fill_in("Start Date", with: "2012-01-01")
    element = find('#accession_rights_statements_ .subrecord-form-heading .btn:not(.show-all)', match: :first)

    element = find(:xpath, '//*[@id="accession_rights_statements__0__jurisdiction_"]')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)
    find_by_id('accession_rights_statements__0__start_date_').set('2012-01-01')

    # Αdd an external document to the rights statement
    within('#accession_rights_statements_') do
      find('button', :text => 'Add External Document', match: :first).click
      fill_in("Title", with: "Agreement")
      fill_in("Location", with: "http://locationof.agreement.com")

      element = find(:xpath, '//*[@id="accession_rights_statements__0__external_documents__0__identifier_type_"]')
      element.click
      element.send_keys('Trove')
      element.send_keys :tab
    end

    # Save
    find("form#accession_form button[type='submit']", match: :first).click
    expect(page).to have_text "Accession #{accession_title} created"

    click_on('Spawn')
    click_on('Accession')
    expect(page).to have_text 'This Accession has been spawned from'
    expect(page).to have_field('accession_title_', with: accession_title)
    fill_in("Identifier", with: "test_#{Time.now}")
    find("form#accession_form button[type='submit']", match: :first).click
    expect(page).to have_text "Accession #{accession_title} created"

    dates = all('section#accession_dates_ .subrecord-form-container ul')
    expect(dates.length).to eq(1)

    within dates.first do
      sub_element = find('#accession_dates__0__label_')
      expect(sub_element.value).to eq('digitized')

      sub_element = find('#accession_dates__0__date_type_')
      expect(sub_element.value).to eq('single')
    end

    rights = all('section#accession_rights_statements_ .subrecord-form-container ul')
    expect(rights.length).to eq(0)
  end

  it 'reports errors when updating an accession with invalid data' do
    click_on('Browse')
    click_on('Accessions')
    first(:link, 'Edit').click
    fill_in('Identifier', with: '')
    click_on('Save')
    expect(find(:xpath, '//div[contains(@class, "error")]', match: :first)).to have_text('Identifier - Property is required but was missing')
  end

  it 'can edit an accession, add two extents and list two them on the view page' do
    click_on('Browse')
    click_on('Accessions')
    first(:link, 'Edit').click

    # Add first extent
    click_on('Add Extent')
    select('Part', from: 'accession_extents__0__portion_')
    fill_in('accession_extents__0__number_', with: '123')
    select('Volumes', from: 'accession_extents__0__extent_type_')

    # Add second extent
    click_on('Add Extent')
    select('Part', from: 'accession_extents__1__portion_')
    fill_in('accession_extents__1__number_', with: '456')
    select('Cassettes', from: 'accession_extents__1__extent_type_')

    click_on('Save')

    extents = all('section#accession_extents_ li')
    expect(extents.length).to eq(2)

    first(:link, accession_title).click
    extents = all('#accession_extents__accordion .panel-heading')
    expect(extents.length).to eq(2)
    expect(extents[0]).to have_text('123 Volumes')
    expect(extents[1]).to have_text('456 Cassettes')

    #
    # it 'can remove an extent when editing an accession' do
    #
    click_on('Browse')

    first(:link, 'Accessions').click
    first(:link, 'Edit').click

    element = find("#accession_extents_ .subrecord-form-remove", match: :first)
    element.click
    click_on('Confirm Removal')

    click_on('Save')

    expect(page).to have_text "Accession #{accession_title} updated"
    extents = all('section#accession_extents_ li')
    expect(extents.length).to eq(1)
  end
end
