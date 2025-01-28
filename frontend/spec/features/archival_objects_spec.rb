# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Archival objects', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "resources_test_#{Time.now.to_i}")
    set_repo @repository
    @user = create_user(@repository => ['repository-managers'])
  end

  before(:each) do
    login_user(@user)
    select_repository(@repository)
  end

  it 'can have a lot of associated records that do not show in the field but are not lost' do
    now = Time.now.to_i

    subjects = []
    accessions = []
    classifications = []
    digital_objects = []
    instances = []
    agents = []

    10.times do |i|
      subjects << create(:subject)
      accessions << create(:accession)
      classifications << create(:classification)
      digital_objects << create(:digital_object, title: "Digital Object Title #{i} #{now}")
      instances = digital_objects.map { |d| { instance_type: 'digital_object', digital_object: { ref: d.uri } } }
      agents << create(:agent_person)
    end

    linked_agents = agents.map do |a|
      { ref: a.uri,
        role: 'creator',
        relator: generate(:relator),
        title: generate(:alphanumstr) }
    end

    resource = create(:resource,
                      linked_agents: linked_agents,
                      subjects: subjects.map { |s| { ref: s.uri } },
                      related_accessions: accessions.map { |a| { ref: a.uri } },
                      instances: instances,
                      classifications: classifications.map { |c| { ref: c.uri } })

    run_index_round

    visit "resources/#{resource.id}/edit"

    click_on 'Add Extent'
    fill_in 'resource_extents__1__number_', with: '5'
    select 'Volumes', from: 'resource_extents__1__extent_type_'

    # Click on save
    find('button', text: 'Save Resource', match: :first).click

    expect(page).to have_text "Resource #{resource.title} updated"

    elements = all('.alert-too-many')
    elements.each do |element|
      element.click
    end

    [subjects, accessions, classifications, digital_objects].each do |entities|
      entities.each do |entity|
        element = find("##{entity[:uri].gsub('/', '_')}")
        expect(element.text).to match(/#{entity.title}/)
      end
    end

    linked_agents.each_with_index do |agent, index|
      element = find("#resource_linked_agents__#{index}__role_")
      expect(element.value).to eq(agent[:role])

      if agent.key?(:title)
        element = find("#resource_linked_agents__#{index}__title_")
        expect(element.value).to eq(agent[:title])
      end

      element = find(:xpath, "//input[@name='resource[linked_agents][#{index}][relator]']", visible: false)
      expect(element.value).to eq(agent[:relator])

      element = find("#resource_linked_agents__#{index}_ .linker-wrapper .token-input-token")
      expect(element.text).to match(/#{agents[index][:primary_name]}/)
    end
  end

  it 'can populate the archival object tree' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    run_index_round
    visit "resources/#{resource.id}/edit"

    click_on 'Add Child'

    expect(page).to have_css '#archival_object_title_'
    expect(page).to have_css '#archival_object_level_'
    fill_in 'Title', with: "Archival Object Title #{now}"
    select 'Item', from: 'archival_object_level_'

    # Click on save
    find('#createPlusOne', match: :first).click

    expect(page).to have_text "Archival Object Archival Object Title #{now} on Resource Resource Title #{now} created"

    %w[January February December].each do |month|
      sleep 5
      expect(page).to have_text 'Archival Object'
      expect(page).to have_css '#archival_object_title_'
      expect(page).to have_css '#archival_object_level_'

      fill_in 'Title', with: "Archival Object Title #{month} #{now}"
      select 'Item', from: 'archival_object_level_'

      # Click on save
      find('#createPlusOne', match: :first).click
      expect(page).to have_text "Archival Object Archival Object Title #{month} #{now} on Resource Resource Title #{now} created"
    end

    elements = all('#tree-container .largetree-node.indent-level-1').map { |li| li.text.strip }

    %w[January February December].each do |month|
      expect(elements.any? { |element| element =~ /#{month}/ }).to be_truthy
    end
  end

  it 'can cancel edits to Archival Objects' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", component_id: 'component-id', resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    within '#tree-container' do
      click_on archival_object.title
    end

    expect(page).to have_css '.ui-resizable-handle.ui-resizable-s'

    fill_in 'archival_object_component_id_', with: 'unimportant change'


    within '#tree-container' do
      click_on resource.title
    end

    within '#saveYourChangesModal' do
      click_on 'Dismiss Changes'
    end

    element = find('#form_resource')
    expect(element).to have_text resource.title
  end

  it 'reports warnings when updating an Archival Object with invalid data' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", component_id: 'component-id', resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    element = find('#form_archival_object')
    expect(element).to have_text archival_object.title

    fill_in 'archival_object_title_', with: ''

    # Click on save
    find('button', text: 'Save Archival Object', match: :first).click

    within '#form_messages' do
      element = find('.alert.alert-danger.with-hide-alert')
      expect(element).to have_text 'Dates - one or more required (or enter a Title)'
      expect(element).to have_text 'Title - must not be an empty string (or enter a Date)'
    end
  end

  it 'can update an existing Archival Object' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", component_id: 'component-id', resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    element = find('#form_archival_object')
    expect(element).to have_text archival_object.title

    element = find('#archival_object_title_')
    expect(element.value).to eq archival_object.title

    fill_in 'archival_object_title_', with: "Updated Archival Object Title #{now}"

    # Click on save
    find('button', text: 'Save Archival Object', match: :first).click

    expect(page).to have_text "Archival Object Updated Archival Object Title #{now} updated"

    element = find('h2')
    expect(element.text).to eq "Updated Archival Object Title #{now} Archival Object"
  end

  it 'can add a assign, remove, and reassign a Subject to an archival object' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    within '#form_archival_object' do
      click_on 'Add Subject'
    end

    find('#archival_object_subjects_ #dropdownMenuSubjectsToggle').click
    within '#dropdownMenuSubjects' do
      click_on 'Create'
    end

    within '#archival_object_subjects__0__ref__modal' do
      find('button', text: 'Add Term/Subdivision', match: :first).click
      select 'Local', from: 'subject_source_'
      fill_in 'subject_terms__0__term_', with: "Test Term 1 #{now}"
      select 'Function', from: 'subject_terms__0__term_type_'
      fill_in 'subject_terms__1__term_', with: "Test Term 2 #{now}"
      select 'Genre / Form', from: 'subject_terms__1__term_type_'

      click_on 'Create and Link'
    end

    run_index_round

    within '#archival_object_subjects__0__ref__combobox' do
      find('.token-input-delete-token').click
    end

    fill_in 'token-input-archival_object_subjects__0__ref_', with: "Test Term 1 #{now}"
    find('li.token-input-dropdown-item2').click

    # Click on save
    find('button', text: 'Save Archival Object', match: :first).click

    expect(page).to have_text "Archival Object Archival Object Title #{now} updated"

    element = find('#archival_object_subjects_ ul.token-input-list')
    expect(element).to have_text "Test Term 1 #{now}"
  end

  it 'can view a read only Archival Object' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(:archival_object, title: "Archival Object Title #{now}", resource: { 'ref' => resource.uri })
    run_index_round

    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"

    click_on 'Close Record'

    element = find('.record-pane h2')
    expect(element).to have_text archival_object.title
  end

  it 'shows component id in browse view for archival objects' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(
      :archival_object,
      title: "Archival Object Title #{now}",
      component_id: "Component Id #{now}",
      resource: { 'ref' => resource.uri }
    )
    run_index_round

    click_on 'Browse'
    click_on 'Resources'
    click_on 'Show Components'

    element = find('#tabledSearchResults')
    expect(element).to have_text 'Identifier'

    row = find('tr', text: archival_object.component_id)
    within row do
      elements = all('td')
      expect(elements[1].text).to eq 'Archival Object'
      expect(elements[3].text).to eq "Component Id #{now}"
    end

    expect(page).to_not have_text 'Component ID'
  end

  it 'shows component id for search and filter to archival objects' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(
      :archival_object,
      title: "Archival Object Title #{now}",
      component_id: "Component Id #{now}",
      resource: { 'ref' => resource.uri }
    )
    run_index_round

    find('#global-search-button').click

    click_on 'Archival Object'

    element = find('#tabledSearchResults')
    expect(element).to have_text 'Component ID'

    fill_in 'filter-text', with: archival_object.component_id
    find('button[title="Filter by text"]').click

    row = find('tr', text: archival_object.component_id)
    within row do
      elements = all('td')
      expect(elements[0].text).to eq archival_object.title
      expect(elements[2].text).to eq "Component Id #{now}"
    end

    expect(page).to_not have_text 'Identifier'
  end

  it 'allows for publication and unpublication of all or part of the record tree' do
    now = Time.now.to_i
    resource = create(:resource, title: "Resource Title #{now}")
    archival_object = create(
      :archival_object,
      title: "Archival Object Title #{now}",
      component_id: "Component Id #{now}",
      resource: { 'ref' => resource.uri }
    )
    run_index_round

    visit "resources/#{resource.id}/edit"

    # The resource was created without specifying publish, so it should be unpublished
    element = find('#resource_publish_')
    expect(element.checked?).to eq(false)

    click_on 'Publish All'
    within '#confirmChangesModal' do
      click_on 'Publish All'
    end

    element = find('#resource_publish_')
    expect(element.checked?).to eq(true)

    # Confirm that the archival object is also published
    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"
    element = find('h2')
    expect(element).to have_text "#{archival_object.title}"
    element = find('#archival_object_publish_')
    expect(element.checked?).to eq(true)

    # Unpublish the archival object
    click_on 'Unpublish All'
    within '#confirmChangesModal' do
      click_on 'Unpublish All'
    end

    element = find('h2')
    expect(element).to have_text "#{archival_object.title}"

    element = find('#archival_object_publish_')
    expect(element.checked?).to eq(false)

    # Confirm that this hasn't unpublished the resource
    visit "resources/#{resource.id}/edit"
    element = find('h2')
    expect(element).to have_text "#{resource.title}"
    element = find('#resource_publish_')
    expect(element.checked?).to eq(true)

    # Unpublish all from the resource
    click_on 'Unpublish All'
    within '#confirmChangesModal' do
      click_on 'Unpublish All'
    end
    element = find('#resource_publish_')
    expect(element.checked?).to eq(false)

    # Confirm that the archival object is still unpublished
    visit "resources/#{resource.id}/edit#tree::archival_object_#{archival_object.id}"
    element = find('#archival_object_publish_')
    expect(element.checked?).to eq(false)

    # Publish the archival object
    click_on 'Publish All'
    within '#confirmChangesModal' do
      click_on 'Publish All'
    end
    element = find('#archival_object_publish_')
    expect(element.checked?).to eq(true)

    # Confirm that this hasn't published the resource
    visit "resources/#{resource.id}/edit"
    element = find('#resource_publish_')
    expect(element.checked?).to eq(false)

    # Finally, unpublish all to tidy up
    click_on 'Unpublish All'
    within '#confirmChangesModal' do
      click_on 'Unpublish All'
    end

    element = find('#resource_publish_')
    expect(element.checked?).to eq(false)
  end
end
