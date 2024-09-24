# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Classifications', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "classification_test_A_#{Time.now.to_i}", publish: true)
    @agent = create(:agent_person)
    @admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')

    run_all_indexers
  end

  before(:each) do
    login_user(@admin)
    select_repository(@repository)
  end

  it 'allows you to create a classification tree' do
    now = Time.now.to_i
    agent_name = @agent.names.first['sort_name']

    click_on 'Create'
    click_on 'Classification'
    fill_in 'Identifier', with: "Identifier #{now}"
    fill_in 'Title', with: "Title #{now}"

    # Creator AJAX drodown
    element = find('#token-input-classification_creator__ref_')
    element.fill_in with: agent_name
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Classification', match: :first).click
    expect(page).to have_text "Classification Title #{now} created"
    element = find('div.agent_person')
    expect(element).to have_text agent_name

    # Create classification child
    click_on 'Add Child'
    expect(page).to have_text('Classification Term')

    within '#basic_information' do
      fill_in 'Identifier', with: "Identifier child #{now}"
      fill_in 'Title', with: "Title child #{now}"
      # Creator AJAX drodown
      element = find('#token-input-classification_term_creator__ref_')
      element.fill_in with: agent_name
      dropdown_items = all('li.token-input-dropdown-item2')
      dropdown_items.first.click
    end

    # Click on save
    find('button', text: 'Save Classification Term', match: :first).click
    expect(page).to have_text "Classification Term Title child #{now} created"
    element = find('div.agent_person')
    expect(element).to have_text agent_name
  end

  it 'allows you to link a resource to a classification' do
    now = Time.now.to_i

    classification = create(
      :json_classification,
      :title => "Classification Title #{now}",
      :identifier => "Classification Identifier #{now}"
    )

    run_index_round

    click_on 'Create'
    click_on 'Resource'
    fill_in 'Title', with: "Resource title #{now}"
    fill_in 'Identifier', with: "Resource identifier #{now}"
    select 'Collection', from: 'Level of Description'
    element = find('#resource_lang_materials__0__language_and_script__language_')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)

    within '#resource_dates_' do
      select 'Creation', from: 'Label'
      select 'Single', from: 'Type'
      fill_in 'Begin', with: '1978'
    end

    within '#resource_extents_' do
      select 'Part', from: 'Portion'
      select 'Volumes', from: 'Type'
      fill_in 'Number', with: '123456789'
    end

    element = find('#resource_finding_aid_language_')
    element.click
    element.send_keys('AU')
    element.send_keys(:tab)

    element = find('#resource_finding_aid_script_')
    element.click
    element.send_keys('Latin')
    element.send_keys(:tab)

    click_on 'Add Classification'

    # Classification AJAX drodown
    element = find('#token-input-resource_classifications__0__ref_')
    element.fill_in with: classification.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Resource', match: :first).click
    expect(page).to have_text "Resource Resource title #{now} created"
    click_on 'Close Record'

    element = find('#resource_classifications_')
    expect(element).to have_text(classification.title)
  end

  it 'allows you to link an accession to a classification' do
    now = Time.now.to_i

    classification = create(
      :json_classification,
      :title => "Classification Title #{now}",
      :identifier => "Classification Identifier #{now}"
    )

    run_index_round

    click_on 'Create'
    click_on 'Accession'

    fill_in 'Title', with: "Accession Title #{now}"
    fill_in 'Identifier', with: "Accession Identifier #{now}"

    click_on 'Add Classification'

    element = find('#token-input-accession_classifications__0__ref_')
    element.fill_in with: classification.title
    dropdown_items = all('li.token-input-dropdown-item2')
    dropdown_items.first.click

    # Click on save
    find('button', text: 'Save Accession', match: :first).click
    expect(page).to have_text "Accession Accession Title #{now} created"

    element = find('#accession_classifications_')
    expect(element).to have_text(classification.title)
  end

  it 'has the linked records on the classifications view page' do
    resource = create(:resource)
    classification = create(:classification, linked_records: [{ ref: resource.uri }])
    classification_term = create(:classification_term, classification: { 'ref' => classification.uri })
    accession = create(:accession, classifications: [{ ref: classification_term.uri }])

    run_all_indexers

    visit "/"
    visit "classifications/#{classification.id}"
    expect(page).to have_text resource.title
    tree_element = find("#classification_term_#{classification_term.id} a.record-title")
    tree_element.click
    expect(page).to have_text accession.title
  end
end
