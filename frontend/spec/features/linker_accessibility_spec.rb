# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Linker Accessibility by Variant', js: true do
  # Linker Variants Tested
  # ------------------------------------------------------------------------------------------------
  # Linker Type        | Multiplicity | Create? | Unique Characteristics
  # ------------------------------------------------------------------------------------------------
  # agents             | many         | yes     | nested Create submenu (4 agent types)
  # subjects           | many         | yes     | dual label system, term_type_filter
  # classifications    | many         | no      | links to classifications and classification_terms
  # accessions         | one          | no      | related_accessions template
  # accession_links    | one          | no      | accession_links template
  # container_profiles | one          | yes     | dedicated typeahead endpoint
  # top_containers     | one          | yes     | uri-scoped typeahead (by resource/accession)
  # ------------------------------------------------------------------------------------------------

  let(:now) { Time.now.to_i }
  let(:linker_wrapper_selector) { '.linker-wrapper' }


  before(:all) do
    @repo = create(:repo, repo_code: "linker_accessibility_test_#{Time.now.to_i}", publish: true)
    set_repo(@repo)
  end

  before(:each) do
    login_admin
    select_repository(@repo)
  end

  def go_to_resource_new_linker(section_name, add_button_text)
    visit '/resources/new'
    expect(page).to have_css('form#resource_form')
    click_on section_name
    click_on add_button_text
    expect(page).to have_css("#{linker_container_selector} #{linker_wrapper_selector}")
  end

  def go_to_resource_edit_linker(resource, section_name)
    visit "/resources/#{resource.id}/edit"
    expect(page).to have_css('form#resource_form')
    click_on section_name
    expect(page).to have_css("#{linker_container_selector} #{linker_wrapper_selector}")
  end

  describe 'agents linker' do
    let(:linker_container_selector) { '#resource_linked_agents_' }
    let(:searchable_record) { create(:agent_person) }
    let(:search_term) { searchable_record.names.first['primary_name'] }
    let(:linked_record) { create(:agent_person) }
    let(:parent_resource) do
      create(:resource, linked_agents: [{ 'ref' => linked_record.uri, 'role' => 'creator' }])
    end
    let(:navigate_to_empty_linker) do
      -> { go_to_resource_new_linker('Agent Links', 'Add Agent Link') }
    end
    let(:record_with_link) { parent_resource }
    let(:navigate_to_linked_record) do
      -> { go_to_resource_edit_linker(parent_resource, 'Agent Links') }
    end

    include_examples 'linker accessibility states'
  end

  describe 'subjects linker' do
    let(:linker_container_selector) { '#resource_subjects_' }
    let(:searchable_record) { create(:subject) }
    let(:search_term) { searchable_record.terms.first['term'] }
    let(:linked_record) { create(:subject) }
    let(:parent_resource) do
      create(:resource, subjects: [{ 'ref' => linked_record.uri }])
    end
    let(:navigate_to_empty_linker) do
      -> { go_to_resource_new_linker('Subjects', 'Add Subject') }
    end
    let(:record_with_link) { parent_resource }
    let(:navigate_to_linked_record) do
      -> { go_to_resource_edit_linker(parent_resource, 'Subjects') }
    end

    include_examples 'linker accessibility states'
  end

  describe 'classifications linker' do
    let(:linker_container_selector) { '#resource_classifications_' }
    let(:searchable_record) { create(:classification) }
    let(:search_term) { searchable_record.title }
    let(:linked_record) { create(:classification) }
    let(:parent_resource) do
      create(:resource, classifications: [{ 'ref' => linked_record.uri }])
    end
    let(:navigate_to_empty_linker) do
      -> { go_to_resource_new_linker('Classifications', 'Add Classification') }
    end
    let(:record_with_link) { parent_resource }
    let(:navigate_to_linked_record) do
      -> { go_to_resource_edit_linker(parent_resource, 'Classifications') }
    end

    include_examples 'linker accessibility states'
  end

  describe 'accessions linker' do
    let(:linker_container_selector) { '#resource_related_accessions_' }
    let(:accession_title) { "Searchable Accession #{now}" }
    let(:searchable_record) { create(:accession, title: accession_title) }
    let(:search_term) { accession_title }
    let(:linked_record) { create(:accession) }
    let(:parent_resource) do
      create(:resource, related_accessions: [{ 'ref' => linked_record.uri }])
    end
    let(:navigate_to_empty_linker) do
      -> { go_to_resource_new_linker('Related Accessions', 'Add Related Accession') }
    end
    let(:record_with_link) { parent_resource }
    let(:navigate_to_linked_record) do
      -> { go_to_resource_edit_linker(parent_resource, 'Related Accessions') }
    end

    include_examples 'linker accessibility states'
  end

  describe 'accession links linker' do
    let(:linker_container_selector) { '#archival_object_accession_links_' }
    let(:accession_title) { "AO Linked Accession #{now}" }
    let(:searchable_record) { create(:accession, title: accession_title) }
    let(:search_term) { accession_title }
    let(:linked_record) { create(:accession) }
    let(:parent_resource) { create(:resource) }
    let(:archival_object) do
      create(
        :archival_object,
        title: "AO with Accession Link #{now}",
        resource: { 'ref' => parent_resource.uri },
        accession_links: [{ 'ref' => linked_record.uri }]
      )
    end
    let(:navigate_to_empty_linker) do
      -> {
        resource = create(:resource)
        ao = create(
          :archival_object,
          title: "Test Archival Object #{now}",
          resource: { 'ref' => resource.uri }
        )
        visit "/resources/#{resource.id}/edit#tree::archival_object_#{ao.id}"
        expect(page).to have_css('form#archival_object_form')
        expect(page).to have_css('.largetree-node.current')
        click_on 'Accession Links'
        click_on 'Add Accession Link'
        expect(page).to have_css("#{linker_container_selector} #{linker_wrapper_selector}")
      }
    end
    let(:record_with_link) { archival_object }
    let(:navigate_to_linked_record) do
      -> {
        visit "/resources/#{parent_resource.id}/edit#tree::archival_object_#{archival_object.id}"
        expect(page).to have_css('form#archival_object_form')
        expect(page).to have_css('.largetree-node.current')
        click_on 'Accession Links'
        expect(page).to have_css("#{linker_container_selector} #{linker_wrapper_selector}")
      }
    end

    include_examples 'linker accessibility states'
  end

  describe 'container profiles linker' do
    let(:linker_wrapper_selector) { '#new_top_container_form .linker-wrapper' }
    let(:searchable_record) { create(:container_profile) }
    let(:search_term) { searchable_record.name }
    let(:linked_record) { create(:container_profile) }
    let(:top_container) do
      create(:top_container, container_profile: { 'ref' => linked_record.uri })
    end
    let(:navigate_to_empty_linker) do
      -> {
        visit '/top_containers/new'
        expect(page).to have_css('#new_top_container_form')
        expect(page).to have_css(linker_wrapper_selector)
      }
    end
    let(:record_with_link) { top_container }
    let(:navigate_to_linked_record) do
      -> {
        visit "/top_containers/#{top_container.id}/edit"
        expect(page).to have_css('#new_top_container_form')
        expect(page).to have_css(linker_wrapper_selector)
      }
    end

    include_examples 'linker accessibility states'
  end

  describe 'top containers linker' do
    let(:linker_container_selector) { '#resource_instances_' }
    let(:searchable_record) { create(:top_container) }
    let(:search_term) { searchable_record.indicator }
    let(:linked_record) { create(:top_container) }
    let(:parent_resource) do
      create(
        :resource,
        instances: [
          build(
            :json_instance,
            sub_container: build(
              :json_sub_container,
              top_container: { 'ref' => linked_record.uri }
            )
          )
        ]
      )
    end
    let(:navigate_to_empty_linker) do
      -> {
        visit '/resources/new'
        expect(page).to have_css('form#resource_form')
        click_on 'Add Container Instance'
        expect(page).to have_css("#{linker_container_selector} #{linker_wrapper_selector}")
      }
    end
    let(:record_with_link) { parent_resource }
    let(:navigate_to_linked_record) do
      -> { go_to_resource_edit_linker(parent_resource, 'Instances') }
    end

    include_examples 'linker accessibility states'
  end
end
