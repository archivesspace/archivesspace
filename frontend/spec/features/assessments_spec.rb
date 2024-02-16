# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Assessments', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "assessments_test_A_#{Time.now.to_i}", publish: true)
    @another_repository = create(:repo, repo_code: "assessments_test_B_#{Time.now.to_i}", publish: true)
    @manager_user = create_user(@repository => ['repository-managers'], @another_repository => ['repository-managers'])

    run_all_indexers
  end

  before(:each) do
    login_user(@manager_user)
  end

  it 'can add repository assessment attribute definitions and can delete them' do
    set_repo(@repository)
    select_repository(@repository)

    element = find('.repo-container .btn.dropdown-toggle')
    element.click
    click_on('Manage Assessment Attributes')

    # Add two ratings
    element = find('.add-repo-attribute[data-type=rating]')
    element.click
    element.click
    # Id is not unique for each added element
    input_ratings = all('#ratings__label')
    expect(input_ratings.length).to eq(2)
    input_ratings[0].fill_in with: 'Test input rating 1'
    input_ratings[1].fill_in with: 'Test input rating 2'

    # Add a format
    element = find('.add-repo-attribute[data-type=format]')
    element.click
    input_format = find('#formats__label', match: :first)
    input_format.fill_in with: 'Test input format 1'

    # Add a conservation issue
    element = find('.add-repo-attribute[data-type=conservation_issue]')
    element.click
    input_format = find('#conservation_issues__label', match: :first)
    input_format.fill_in with: 'Test conservation issue 1'

    # Click on save
    element = find('button', text: 'Save Assessment Attributes', match: :first)
    element.click

    expect(page).to have_text 'Assessment Attributes updated'
    expect(page).to have_text 'Test input rating 1'
    expect(page).to have_text 'Test input rating 2'
    expect(page).to have_text 'Test input format 1'
    expect(page).to have_text 'Test conservation issue 1'

    # Delete all previously added attributes
    remove_buttons = all('.remove-repo-attribute')
    expect(remove_buttons.length).to eq(4)
    remove_buttons.each do |button|
      button.click
    end

    # Click on save
    element = find('button', text: 'Save Assessment Attributes', match: :first)
    element.click

    expect(page).to have_text 'Assessment Attributes updated'
    expect(page).to_not have_text 'Test input rating 1'
    expect(page).to_not have_text 'Test input rating 2'
    expect(page).to_not have_text 'Test input format 1'
    expect(page).to_not have_text 'Test conservation issue 1'

    # Check that another repository doesn't have these attributes
    set_repo(@another_repository)
    select_repository(@another_repository)
    element = find('.repo-container .btn.dropdown-toggle')
    element.click
    click_on('Manage Assessment Attributes')
    input_ratings = all('#ratings__label')
    expect(input_ratings.length).to eq(0)
    formats = all('#formats__label')
    expect(formats.length).to eq(0)
    conservation_issues = all('#conservation_issues__label')
    expect(conservation_issues.length).to eq(0)
  end

  it 'can create an assessment, with ratings and rating notes, links to records and users, and shows it in the listing' do
    set_repo(@repository)
    select_repository(@repository)

    archivist_user = create_user(@repository => ['repository-archivists'])

    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")
    digital_object = create(:digital_object, title: "Test digital object #{now}")
    resource = create(
      :resource,
      instances: [
      {
        instance_type: 'digital_object',
        digital_object: { ref: digital_object.uri }
      }
    ])
    archival_object = create(
      :archival_object,
      title: "Test archival object #{now}",
      resource: { ref: resource.uri }
    )

    run_index_round

    click_on 'Create'
    click_on 'Assessment'

    # Records AJAX drodown
    element = find('#token-input-assessment_records_')
    element.fill_in with: accession.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    element = find('#token-input-assessment_records_')
    element.fill_in with: digital_object.title
    dropdown_items = all('li.token-input-dropdown-item')
    dropdown_items.first.click

    element = find('#token-input-assessment_records_')
    element.fill_in with: archival_object.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Surveyed by AJAX dropdown
    element = find('#token-input-assessment_surveyed_by_')
    element.fill_in with: archivist_user.username
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Label: Review Required?
    element = find('#assessment_review_required_')
    element.click

    # Label: Who Needs to Review AJAX dropdown
    element = find('#token-input-assessment_reviewer_')
    element.fill_in with: archivist_user.username
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Assessment Information | Ratings
    find("#assessment_ratings__0__value_[value='1']").click
    find("#assessment_ratings__1__value_[value='2']").click
    find("#assessment_ratings__2__value_[value='3']").click
    find("#assessment_ratings__3__value_[value='4']").click
    find("#assessment_ratings__4__value_[value='5']").click
    find("#assessment_ratings__5__value_[value='4']").click
    find("#assessment_ratings__6__value_[value='3']").click
    note_buttons = all('.assessment-add-rating-note')
    note_buttons.each_with_index do |button, index|
      button.click
      fill_in "assessment_ratings__#{index}__note_", with: "Test assessment rating note for rating #{index+1}"
    end

    # List of Material Types / Formats
    find('#assessment_formats__3__value_').click
    find('#assessment_formats__14__value_').click

    # Conservation Issues
    find('#assessment_conservation_issues__5__value_').click
    find('#assessment_conservation_issues__8__value_').click

    # External documents
    click_on('Add External Document')
    within '#assessment_external_documents_' do
      fill_in 'Title', with: 'Test external document title'
      fill_in 'Location', with: 'Test external document location'
    end

    # Click on save
    find('button', text: 'Save Assessment', match: :first).click

    expect(page).to have_text 'Assessment Created'
    expect(page).to have_text accession.title
    expect(page).to have_text digital_object.title
    expect(page).to have_text archival_object.title
    linked_agents = all('.token-input-token .agent_person')
    expect(linked_agents[0]).to have_text(archivist_user.username)
    expect(linked_agents[1]).to have_text(archivist_user.username)

    # Assessment Information | Ratings
    find("#assessment_ratings__0__value_[value='1']:checked")
    find("#assessment_ratings__1__value_[value='2']:checked")
    find("#assessment_ratings__2__value_[value='3']:checked")
    find("#assessment_ratings__3__value_[value='4']:checked")
    find("#assessment_ratings__4__value_[value='5']:checked")
    find("#assessment_ratings__5__value_[value='4']:checked")
    find("#assessment_ratings__6__value_[value='3']:checked")
    0.upto(6) do |index|
      element = find("#assessment_ratings__#{index}__note_")
      expect(element.value).to eq("Test assessment rating note for rating #{index+1}")
    end

    # Conservation Issues
    find("#assessment_conservation_issues__5__value_:checked")
    find("#assessment_conservation_issues__8__value_:checked")

    # External documents
    element = all('#assessment_external_documents_ .subrecord-form-wrapper')
    expect(element.length).to eq(1)
    expect(element[0]).to have_text('Test external document title')
    expect(element[0]).to have_text('Test external document location')

    run_index_round

    # View the assessment on the listing
    click_on('Browse')
    first(:link, 'Assessments').click
    expect(page).to have_text accession.title
    expect(page).to have_text digital_object.title
    expect(page).to have_text archival_object.title
    expect(page).to have_text archivist_user.username

    click_on('View')
    expect(page).to have_text accession.title
    expect(page).to have_text digital_object.title
    expect(page).to have_text archival_object.title
    expect(page).to have_text archivist_user.username

    # Assessment Information | Ratings
    rating_attributes_table_rows = all('#rating_attributes_table tbody tr')
    rows_length = rating_attributes_table_rows.length
    expect(rows_length).to eq(8)

    rating_attributes_table_cells = all('#rating_attributes_table tbody tr td')

    expect(rating_attributes_table_cells[0]).to have_text('Documentation Quality')
    expect(rating_attributes_table_cells[1]).to have_text('1')
    expect(rating_attributes_table_cells[2]).to have_text('Test assessment rating note for rating 1')

    expect(rating_attributes_table_cells[3]).to have_text('Housing Quality')
    expect(rating_attributes_table_cells[4]).to have_text('2')
    expect(rating_attributes_table_cells[5]).to have_text('Test assessment rating note for rating 2')

    expect(rating_attributes_table_cells[6]).to have_text('Intellectual Access (description)')
    expect(rating_attributes_table_cells[7]).to have_text('3')
    expect(rating_attributes_table_cells[8]).to have_text('Test assessment rating note for rating 3')

    expect(rating_attributes_table_cells[9]).to have_text('Interest')
    expect(rating_attributes_table_cells[10]).to have_text('4')
    expect(rating_attributes_table_cells[11]).to have_text('Test assessment rating note for rating 4')

    expect(rating_attributes_table_cells[12]).to have_text('Physical Access (arrangement)')
    expect(rating_attributes_table_cells[13]).to have_text('5')
    expect(rating_attributes_table_cells[14]).to have_text('Test assessment rating note for rating 5')

    expect(rating_attributes_table_cells[15]).to have_text('Physical Condition')
    expect(rating_attributes_table_cells[16]).to have_text('4')
    expect(rating_attributes_table_cells[17]).to have_text('Test assessment rating note for rating 6')

    expect(rating_attributes_table_cells[18]).to have_text('Reformatting Readiness')
    expect(rating_attributes_table_cells[19]).to have_text('3')
    expect(rating_attributes_table_cells[20]).to have_text('Test assessment rating note for rating 7')

    expect(rating_attributes_table_cells[21]).to have_text('Research Value')
    expect(rating_attributes_table_cells[22]).to have_text('5')

    # List of Material Types / Formats
    element = find('#format_attributes')
    expect(element).to have_text('Audio Materials')
    expect(element).to have_text('Video Materials')

    # Conservation Issues
    element = find('#conservation_issue_attributes')
    expect(element).to have_text('Potential Mold or Mold Damage')
    expect(element).to have_text('Water Damage')
  end

  it 'shows linked assessments on all related entities page' do
    set_repo(@repository)
    select_repository(@repository)

    archivist_user = create_user(@repository => ['repository-archivists'])

    now = Time.now.to_i
    accession = create(:json_accession, title: "Test accession title #{now}")
    digital_object = create(:digital_object, title: "Test digital object #{now}")
    resource = create(
      :resource,
      instances: [
      {
        instance_type: 'digital_object',
        digital_object: { ref: digital_object.uri }
      }
    ])
    archival_object = create(
      :archival_object,
      title: "Test archival object #{now}",
      resource: { ref: resource.uri }
    )

    assessment = create(:json_assessment, {
      'records' => [{'ref' => resource.uri}]
    })

    run_index_round

    visit "assessments/#{assessment.id}/edit"

    # Records AJAX drodown
    element = find('#token-input-assessment_records_')
    element.fill_in with: accession.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    element = find('#token-input-assessment_records_')
    element.fill_in with: digital_object.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    element = find('#token-input-assessment_records_')
    element.fill_in with: archival_object.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Surveyed by AJAX dropdown
    element = find('#token-input-assessment_surveyed_by_')
    element.fill_in with: archivist_user.username
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Assessment', match: :first).click
    expect(page).to have_text 'Assessment Updated'

    run_index_round

    # Check for linked assessments on the accession page
    visit "accessions/#{accession.id}"
    element = all('#linked_assessments #tabledSearchResults tbody tr')
    expect(element.length).to eq(1)
    within element[0] do
      cells = all('td')
      expect(cells[1]).to have_text(assessment.id)
    end

    # Check for linked assessments on the archival object page
    visit "/resolve/readonly?uri=#{archival_object.uri}"
    element = all('#linked_assessments #tabledSearchResults tbody tr')
    expect(element.length).to eq(1)
    within element[0] do
      cells = all('td')
      expect(cells[1]).to have_text(assessment.id)
    end

    # Check for linked assessments on the digital object page
    visit "/resolve/readonly?uri=#{digital_object.uri}"
    element = all('#linked_assessments #tabledSearchResults tbody tr')
    expect(element.length).to eq(1)
    within element[0] do
      cells = all('td')
      expect(cells[1]).to have_text(assessment.id)
    end

    visit '/'

    # Check for linked assessments on the agent_person page
    # Search by archivist_user.username
    element = find('#global-search-box')
    element.fill_in with: archivist_user.username
    element.send_keys :enter
    expect(page).to have_text 'Search Results'

    # Find result that contains the archivist username and click on View
    element = find(:xpath, "//table//tr[td[contains(., '#{archivist_user.username}')]]")
    within element do
      click_on('View')
    end
    expect(page).to have_text 'Assessments - Surveyed By'
    element = all('#linked_assessments_surveyed_by #tabledSearchResults tbody tr')
    expect(element.length).to eq(1)
    within element[0] do
      cells = all('td')
      expect(cells[1]).to have_text(assessment.id)
    end
  end
end
