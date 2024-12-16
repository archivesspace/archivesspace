# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Accessions', js: true do
  let(:accession_title) { 'Test accession title' }
  let(:user) do
    user = create_user(repo => ['repository-archivists'])
    run_index_round

    user
  end

  let(:repo) { create(:repo, repo_code: "accession_test_#{Time.now.to_i}") }

  before(:each) do
    login_user(user)
    run_all_indexers
    select_repository(repo)
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
    click_button('Add Date')
    select 'Digitized', from: 'Label'
    select 'Single', from: 'Type'
    fill_in("Expression", with: "The day before yesterday.")

    # Αdd a second date
    click_button('Add Date')
    element = find('#accession_dates__1__label_')
    element.select 'Digitized'
    element = find('#accession_dates__1__date_type_')
    element.select 'Bulk Dates'
    fill_in 'accession_dates__1__begin_', with: '2021-01-01'
    fill_in 'accession_dates__1__end_', with: '2021-01-03'

    # Add a rights subrecord
    click_on('Add Rights Statement')
    select 'Copyright', from: 'Rights Type'
    select 'Copyrighted', from: 'Status'
    fill_in("Start Date", with: "2012-01-01")

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
    click_on('Save')
    expect(page).to have_text "Accession #{accession_title} created"
    expect(page).to have_field('accession_title_', with: accession_title)

    dates = all('section#accession_dates_ .subrecord-form-container ul li')
    expect(dates.length).to eq(2)

    rights_statement = all('section#accession_rights_statements_ .subrecord-form-container ul li .subrecord-form-wrapper')
    expect(rights_statement.length).to eq(1)
  end

  it 'can update an accession' do
    accession = create(:accession)
    visit "/accessions/#{accession.id}"

    first(:link, 'Edit').click
    updated_title = "Some new title"
    fill_in('Title', with: updated_title)
    click_on('Save')
    expect(page).to have_text "Accession #{updated_title} updated"
    expect(page).to have_field('accession_title_', with: updated_title)
  end

  it 'can spawn an accession from an existing accession' do
    accession = create(:json_accession,
      dates: [
        build(:date,
          date_type: "single",
          label: 'digitized',
          expression: 'The day before yesterday.')
      ],
      :rights_statements => [
        {
          "identifier" => "abc123",
          "rights_type" => "copyright",
          "status" => "copyrighted",
          "jurisdiction" => "AU",
          "start_date" => '1999-01-01',
          "external_documents" => [build(:json_rights_statement_external_document,
            :identifier_type => 'trove')]
        }
      ]
    )

    run_index_round

    visit "/accessions/#{accession.id}"

    click_on('Spawn')
    click_on('Accession')
    expect(page).to have_text 'This Accession has been spawned from'
    expect(page).to have_field('accession_title_', with: accession.title)
    fill_in("Identifier", with: "test_#{Time.now}")
    find("form#accession_form button[type='submit']", match: :first).click
    expect(page).to have_text "Accession #{accession.title} created"

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
    create(:accession)
    run_index_round

    click_on('Browse')
    click_on('Accessions')
    first(:link, 'Edit').click
    fill_in('Identifier', with: '')
    click_on('Save')
    expect(find(:xpath, '//div[contains(@class, "error")]', match: :first)).to have_text('Identifier - Property is required but was missing')
  end

  it 'can edit an accession, add two extents and list them on the view page' do
    accession = create(:accession)
    run_index_round
    visit "/accessions/#{accession.id}/edit"

    # Add first extent
    click_button('Add Extent')

    select('Part', from: 'accession_extents__0__portion_')
    fill_in('accession_extents__0__number_', with: '123')
    select('Volumes', from: 'accession_extents__0__extent_type_')

    # Add second extent
    click_button('Add Extent')

    select('Part', from: 'accession_extents__1__portion_')
    fill_in('accession_extents__1__number_', with: '456')
    select('Cassettes', from: 'accession_extents__1__extent_type_')

    click_on('Save')

    visit "/accessions/#{accession.id}"

    extents = all('#accession_extents__accordion .panel-heading')
    expect(extents.length).to eq(2)
    expect(extents[0]).to have_text('123 Volumes')
    expect(extents[1]).to have_text('456 Cassettes')
  end

  it 'can delete an extent when editing an accession' do
    accession = create(:json_accession,
      extents: [build(:json_extent), build(:json_extent)]
    )
    run_index_round

    visit "/accessions/#{accession.id}/edit"

    element = find("#accession_extents_ .subrecord-form-remove", match: :first)
    element.click
    click_on('Confirm Removal')

    click_on('Save')

    visit "/accessions/#{accession.id}"

    extents = all('#accession_extents__accordion .panel-heading')
    expect(extents.length).to eq(1)
  end

  it 'can delete an external document when editing an accession' do
    accession = create(:json_accession,
      external_documents: [
        {
          title: 'Test external document title A',
          location: 'Test external document location A'
        },
        {
          title: 'Test external document title B',
          location: 'Test external document location B'
        }
      ]
    )

    run_index_round

    visit "/accessions/#{accession.id}/edit"

    # Remove first external document from accession
    element = find("#accession_external_documents_ .subrecord-form-remove", match: :first)
    element.click
    click_on('Confirm Removal')
    click_button('Save')
    expect(page).to have_text "Accession #{accession.title} updated"
    external_documents = all('#accession_external_documents_ .subrecord-form-container ul li')
    expect(external_documents.length).to eq(1)
  end

  it 'can delete an existing date when editing an accession' do
    accession = create(:json_accession,
      dates: [
        build(:date,
          date_type: "single",
          label: 'digitized',
          expression: 'The day before yesterday.'),
        build(:date,
          date_type: "single",
          label: 'digitized',
          expression: 'The day before yesterday.')
      ],
      :rights_statements => [
        {
          "identifier" => "abc123",
          "rights_type" => "copyright",
          "status" => "copyrighted",
          "jurisdiction" => "AU",
          "start_date" => '1999-01-01',
          "external_documents" => [build(:json_rights_statement_external_document,
            :identifier_type => 'trove')]
        }
      ]
    )

    run_index_round

    visit "/accessions/#{accession.id}/edit"

    # Remove first date from accession
    element = find("#accession_dates_ .subrecord-form-remove", match: :first)
    element.click
    click_on('Confirm Removal')
    click_button('Save')
    expect(page).to have_text "Accession #{accession.title} updated"
    dates = all('section#accession_dates_ .subrecord-form-container ul li')
    expect(dates.length).to eq(1)
  end

  it 'can link an accession to an agent as a subject' do
    accession = create(:json_accession,
      extents: [build(:json_extent), build(:json_extent)]
    )

    agent = Time.now.to_i

    create(:agent_person,
           names: [build(:name_person,
                         name_order: 'inverted',
                         primary_name: "Subject Agent #{agent}",
                         rest_of_name: "Subject Agent #{agent}",
                         sort_name: "Subject Agent #{agent}")])

    run_index_round

    visit "/accessions/#{accession.id}"
    click_on('Edit')

    # Add agent link
    click_button('Add Agent Link')
    select('Subject', from: 'accession_linked_agents__0__role_')
    element = find('#token-input-accession_linked_agents__0__ref_', match: :first)
    element.fill_in with: 'Subject Agent'
    dropdown_items = all('#accession_linked_agents__0__ref__listbox li')
    dropdown_items.first.click

    click_button('Add Term/Subdivision')

    fill_in('accession_linked_agents__0__terms__0__term_', with: 'Term 1')
    select('Function', from: 'accession_linked_agents__0__terms__0__term_type_')

    click_button('Add Term/Subdivision')
    fill_in('accession_linked_agents__0__terms__1__term_', with: 'Term 2')
    select('Genre / Form', from: 'accession_linked_agents__0__terms__1__term_type_')

    click_on('Save')

    visit "/accessions/#{accession.id}"

    expect(page).to have_text "Agent Links"

    linked_agents_table_items = all('#accession_linked_agents_ .subrecord-form-fields tbody tr')

    expect(linked_agents_table_items.length).to eq(1)
  end

  it 'shows an error if you try to reuse an identifier' do
    identifier = Time.now
    click_on('Create')
    click_on('Accession')
    fill_in('Title', with: accession_title)
    fill_in("Identifier", with: "test_#{identifier}")
    click_on('Save')
    expect(page).to have_text "Accession #{accession_title} created"

    click_on('Create')
    click_on('Accession')
    fill_in('Title', with: accession_title)
    fill_in("Identifier", with: "test_#{identifier}")
    click_on('Save')

    expect(page).to have_text "Identifier - That ID is already in use"
  end

  it 'can add a rights statement with linked agent to an accession' do
    accession = create(:json_accession)
    run_index_round
    visit "/accessions/#{accession.id}"
    click_on('Edit')

    click_on('Add Rights Statement')
    select 'Copyright', from: 'Rights Type'
    select 'Copyrighted', from: 'Status'
    fill_in("Start Date", with: "2012-01-01")
    element = find(:xpath, '//*[@id="accession_rights_statements__0__jurisdiction_"]')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)

    # Add linked agent
    within '#accession_rights_statements_' do
      click_button('Add Agent Link')
    end

    fill_in('token-input-accession_rights_statements__0__linked_agents__0__ref_', with: 'accession')
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    click_button('Save')
    expect(page).to have_text "Accession #{accession.title} updated"
    run_index_round

    visit "/accessions/#{accession.id}"

    within '#accession_rights_statements_' do
      element = find('#accession_rights_statements_ .accordion-toggle', match: :first)
      element.click
    end

    element = find('#rights_statements_accordion')
    expect(element).to have_text('2012-01-01')
    expect(element).to have_text('Copyright')
    expect(element).to have_text('Austria')
    expect(element).to have_text('Agent Links')
  end

  it 'can create a subject and link it to an accession' do
    accession = create(:json_accession)
    run_index_round
    visit "/accessions/#{accession.id}"
    click_on('Edit')

    click_on('Add Subject')
    element = find('#accession_subjects_ .dropdown-toggle')
    element.click

    within '#dropdownMenuSubjects' do
      click_on 'Create'
    end

    select 'Library of Congress Subject Headings', from: 'Source'
    fill_in("Term", with: "Test subject term #{Time.now.to_i}")
    select 'Function', from: 'Type'
    click_button 'Create and Link'

    run_index_round

    click_on('Add Subject')
    element = all('#accession_subjects_ .dropdown-toggle')
    expect(element.length).to eq(2)
    second_dropdown_toggle = element[1]
    second_dropdown_toggle.click

    within '#dropdownMenuSubjects' do
      click_on 'Browse'
    end

    element = find('#linker-item', match: :first)
    element.click
    click_button 'Link'

    click_button 'Save'
    expect(page).to have_text "Accession #{accession.title} updated"
  end

  it 'can add collection management to an accession and can remove it' do
    accession = create(:json_accession)
    run_index_round
    visit "/accessions/#{accession.id}"
    click_on('Edit')

    click_button('Add Collection Management Fields')
    click_button('Save')
    run_index_round
    click_on('Browse')
    click_link('Collection Management')
    click_on('View')
    click_on('Edit')

    # Remove collection from accession
    element = find("#accession_collection_management_ .subrecord-form-remove", match: :first)
    element.click
    click_on('Confirm Removal')
    click_button('Save')
    expect(page).to have_text "Accession #{accession.title} updated"

    run_index_round

    click_on('Browse')
    element = find('a', text: 'Collection Management', match: :first)
    element.click

    expect(page).to have_text 'Collection Management'
    expect(page).to have_text 'No records found'
  end

  it 'can create an accession which is linked to another accession' do
    accession = create(:json_accession)
    accession_to_link_to = create(:json_accession)
    run_index_round

    visit "/accessions/#{accession.id}"
    click_on('Edit')
    click_on('Add Related Accession')
    # Select: "Part of" Relationship
    dropdown = find('.related-accession-type')
    options = dropdown.all(:css, 'option')
    options[1].select_option

    # Find second accession by AJAX and select the first
    element = find('#token-input-accession_related_accessions__0__ref_')
    element.fill_in with: accession_to_link_to.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    click_on('Save')
    expect(page).to have_text "Accession #{accession.title} updated"
  end

  it 'can show a browse list of accessions' do
    now = Time.now.to_i
    accession_first = create(:json_accession, title: "First Accession #{now}")
    accession_second = create(:json_accession, title: "Second Accession #{now}")
    accession_third = create(:json_accession, title: "Third Accession #{now}")
    run_index_round

    click_on('Browse')
    click_on('Accessions')

    # Search for accession and check results table
    input_text = find('#filter-text')
    input_text.fill_in with: accession_first.title
    input_text.send_keys(:enter)
    find('td', text: accession_first.title)

    # Search for accession and check results table
    input_text = find('#filter-text')
    input_text.fill_in with: accession_second.title
    input_text.send_keys(:enter)
    find('td', text: accession_second.title)

    # Search for accession and check results table
    input_text = find('#filter-text')
    input_text.fill_in with: accession_third.title
    input_text.send_keys(:enter)
    find('td', text: accession_third.title)
  end

  it 'can define a second level sort for a browse list of accessions' do
    create(:json_accession)
    create(:json_accession)

    run_index_round
    click_on('Browse')
    click_on('Accessions')

    click_on('Select')

    element = first('a', text: 'Identifier')
    element.click
    expect(page).to have_text('Identifier Descending')
  end

  context 'when user is a repository manager of the current repo' do
    let(:user) do
      user = create_user(repo => ['repository-managers'])
      run_index_round

      user
    end

    it 'can delete multiple accessions from the listing' do
      now = Time.now.to_i
      accession_first = create(:json_accession, title: "First Accession #{now}", accession_date: Time.now.strftime("%Y-%m-%d"))
      accession_second = create(:json_accession, title: "Second Accession #{now}", accession_date: Time.now.strftime("%Y-%m-%d"))
      run_index_round

      click_on('Browse')
      click_on('Accessions')

      # Sort by descending accession date
      within '#tabledSearchResults' do
        click_link 'Accession Date'
        click_link 'Accession Date'
      end

      # Select first and second entry
      table_rows = all('#tabledSearchResults tbody tr')
      first_entry_checkbox = table_rows[0].find('input[type="checkbox"]')
      first_entry_checkbox.click
      first_entry_checkbox = table_rows[1].find('input[type="checkbox"]')
      first_entry_checkbox.click

      click_on('Delete')
      click_on('Delete Records')
      expect(page).to have_text 'Records deleted'
    end
  end

  it 'can mark a linked_agent as primary' do
    now = Time.now.to_i
    click_on('Create')
    click_on('Accession')
    fill_in('Title', with: accession_title)
    fill_in("Identifier", with: "test_#{Time.now}")
    click_on('Save')

    agent = create(
      :agent_person,
      names: [build(:name_person,
      name_order: 'inverted',
      primary_name: "Subject Agent #{now}",
      rest_of_name: "Subject Agent #{now}",
      sort_name: "Subject Agent #{now}")]
    )

    run_index_round

    click_on('Add Agent Link')
    select 'Creator', from: 'Role'

    # Find agent by AJAX and select the first
    element = find('#token-input-accession_linked_agents__0__ref_')
    element.fill_in with: agent.names.first['primary_name']
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    click_on('Make Primary')

    click_on('Save')
    expect(page).to have_text "Accession #{accession_title} updated"
  end

  describe 'toolbar' do
    it 'has a "more" dropdown menu that is aligned to the right side of its control button' do
      accession = create(:json_accession)
      run_index_round
      visit "/accessions/#{accession.id}"
      expect(page).to have_css(
        '#other-dropdown > .dropdown-menu.dropdown-menu-right',
        visible: false
      )
    end
  end
end
