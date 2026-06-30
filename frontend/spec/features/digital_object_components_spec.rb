# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Digital Object Components', js: true do
  before(:all) do
    @repository = create(:repo, repo_code: "digital_object_components_test_#{Time.now.to_i}")
    set_repo @repository

    @user = create_user(@repository => ['repository-archivists'])
  end

  before(:each) do
    login_user(@user)
    select_repository(@repository)
  end

  it 'reports errors if adding a child with no title to a Digital Object' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}")
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on 'Add Child'

    wait_for_ajax

    element = find('h2')
    expect(element.text).to eq "Digital Object Component Digital Object Component"

    fill_in 'digital_object_component_component_id_', with: "Digital Object Identifier #{now}"

    find('#createPlusOne').click

    element = find('.alert.alert-danger.with-hide-alert')
    expect(element.text).to eq "Dates - you must provide a Label, Title or Date\nTitle - you must provide a Label, Title or Date\nLabel - you must provide a Label, Title or Date"
  end

  it 'can populate the digital object component tree' do
    now = Time.now.to_i
    digital_object = create(:digital_object, title: "Digital Object Title #{now}", dates: [], extents: [])
    run_index_round

    visit "digital_objects/#{digital_object.id}/edit"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object.title} Digital Object")

    click_on 'Add Child'

    fill_in 'digital_object_component_component_id_', with: "Child 1 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 1 #{now}"

    find('#createPlusOne').click
    wait_for_ajax

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 1 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 2 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 2 #{now}"

    find('#createPlusOne').click
    wait_for_ajax

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 2 #{now} created on Digital Object Digital Object Title #{now}"

    fill_in 'digital_object_component_component_id_', with: "Child 3 #{now}"
    fill_in 'digital_object_component_title_', with: "Child 3 #{now}"

    # Click on save
    find('button', text: 'Save Digital Object', match: :first).click

    expect(page).to have_selector('h2', visible: true, text: "Digital Object Component Digital Object Component")
    expect(page).to have_content "Digital Object Component Child 3 #{now} created on Digital Object Digital Object Title #{now}"

    elements = all('.largetree-node.indent-level-1')
    expect(elements.length).to eq 3
    expect(elements[0]).to have_text "Child 1 #{now}"
    expect(elements[1]).to have_text "Child 2 #{now}"
    expect(elements[2]).to have_text "Child 3 #{now}"
  end

  it 'provides alt text for Digital Object Component file version images based on caption or title' do
    now = Time.now.to_i
    digital_object = create(
      :digital_object,
      title: "Digital Object Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    digital_object_component = create(
      :digital_object_component,
      digital_object: { ref: digital_object.uri },
      title: "Digital Object Component Title #{now}",
      file_versions: [
        {
          file_uri: "File URI 1 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 1 #{now}"
        },
        {
          file_uri: "File URI 2 #{now}",
          file_format_name: "jpeg",
          caption: "File Format Caption 2 #{now}"
        }
      ]
    )

    run_index_round

    visit "digital_objects/#{digital_object.id}/#tree::digital_object_component_#{digital_object_component.id}"

    expect(page).to have_selector('h2', visible: true, text: "#{digital_object_component.title} Digital Object Component")

    expect(page).to have_css('#digital_object_component_file_versions__file_version_0', visible: false, text: "File Format Caption 1 #{now}")
    expect(page).to have_css('#digital_object_component_file_versions__file_version_1', visible: false, text: "File Format Caption 2 #{now}")
  end

  describe 'title field mixed content validation' do
    let(:digital_object) { create(:digital_object, title: 'Digital Object') }

    context 'for a child Digital Object Component' do
      let(:digital_object_component) { create(:digital_object_component, title: 'Digital Object Component', digital_object: { ref: digital_object.uri }) }
      let(:edit_path) { "digital_objects/#{digital_object.id}/edit#tree::digital_object_component_#{digital_object_component.id}" }
      let(:input_field_id) { 'digital_object_component_title_' }

      it_behaves_like 'validating mixed content'
    end
  end

  describe 'Linked Agents is_primary behavior' do
    let(:agent) { create(:agent_person) }

    before do
      set_repo @repository
      login_admin
      select_repository(@repository)
    end

    context 'for child Digital Object Components' do
      let(:record_type) { 'digital_object_component' }
      let(:parent_digital_object) do
        create(
          :digital_object,
          title: "Digital Object Title #{Time.now.to_i}"
        )
      end
      let(:record) do
        create(
          :digital_object_component,
          digital_object: { ref: parent_digital_object.uri },
          title: "Digital Object Component Title #{Time.now.to_i}",
          linked_agents: [
            { ref: agent.uri, role: 'creator' }
          ],
          rights_statements: [
            build(
              :json_rights_statement,
              rights_type: 'copyright',
              status: 'copyrighted',
              jurisdiction: 'AU',
              start_date: Time.now.strftime('%Y-%m-%d'),
              linked_agents: [
                { ref: agent.uri, role: 'rights_holder' }
              ]
            )
          ]
        )
      end
      let(:edit_path) { "/digital_objects/#{parent_digital_object.id}/edit#tree::digital_object_component_#{record.id}" }

      it_behaves_like 'supporting is_primary on top-level linked agents'
      it_behaves_like 'not supporting is_primary on rights statement linked agents'
    end
  end

  context 'when multilingual content enabled' do
    before do
      AppConfig[:multilingual_content] = true
    end

    after do
      AppConfig[:multilingual_content] = false
    end

    let(:now) { Time.now.to_i }
    let(:english_digital_object_title) { "English Digital Object Title #{now}" }
    let(:english_doc_title) { "English Digital Object Component Title #{now}" }

    let(:digital_object) do
      create(:json_digital_object,
             title: english_digital_object_title,
             dates: [],
             lang_descriptions: [
               JSONModel(:language_and_script_of_description).new(
                 'language' => 'eng', 'script' => 'Latn', 'is_primary' => true
               ),
               JSONModel(:language_and_script_of_description).new(
                 'language' => 'fre', 'script' => 'Latn', 'is_primary' => false
               )
             ])
    end

    let(:digital_object_component) do
      create(:json_digital_object_component,
             title: english_doc_title,
             digital_object: { 'ref' => digital_object.uri })
    end

    before do
      digital_object_component
      run_index_round
      visit "digital_objects/#{digital_object.id}/edit#tree::digital_object_component_#{digital_object_component.id}"
    end

    it 'shows the language selector dropdown inherited from the parent digital object, defaulting to the primary language value' do
      expect(page).to have_css('#language-of-description-dropdown')
      expect(page).to have_field('digital_object_component_title_', with: english_doc_title)
    end

    it 'updates the URL when a non-primary language is selected from the dropdown' do
      within '#language-of-description-dropdown' do
        find('.dropdown-toggle').click
        find('input[type="radio"][value="fre_Latn"]').choose
      end

      expect(page.current_url).to include('language_of_description=fre_Latn')
    end

    it 'saves non-primary language edits to that language without modifying the primary language' do
      within '#language-of-description-dropdown' do
        find('.dropdown-toggle').click
        find('input[type="radio"][value="fre_Latn"]').choose
      end

      french_doc_title = "French Digital Object Component Title #{now}"
      fill_in 'digital_object_component_title_', with: french_doc_title
      find('button', text: 'Save Digital Object Component', match: :first).click

      expect(page).to have_text "Digital Object Component #{french_doc_title} updated"

      visit "digital_objects/#{digital_object.id}/edit?language_of_description=eng_Latn#tree::digital_object_component_#{digital_object_component.id}"
      expect(page).to have_field('digital_object_component_title_', with: english_doc_title)

      visit "digital_objects/#{digital_object.id}/edit?language_of_description=fre_Latn#tree::digital_object_component_#{digital_object_component.id}"
      expect(page).to have_field('digital_object_component_title_', with: french_doc_title)
    end
  end
end
