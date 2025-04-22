# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Agents Required Fields', js: true do
  before(:each) do
    login_admin
  end

  let(:all_possible_items) do
    [
      'Basic Information',
      'Record Control Information',
      'Record IDs',
      'Record Info',
      'Other Agency Codes',
      'Convention Declarations',
      'Metadata Rights Declarations',
      'Maintenance History',
      'Sources',
      'Alternate Sets',
      'Identity Information',
      'Entity IDs',
      'Name Forms',
      'Description Information',
      'Dates of Existence',
      'Genders',
      'Places',
      'Occupations',
      'Functions',
      'Topics',
      'Languages Used',
      'Contact Details',
      'External Documents',
      'Relation Information',
      'Related External Resources'
    ]
  end

  let(:light_mode_common_items) do
    [
      'Basic Information',
      'Identity Information',
      'Entity IDs',
      'Name Forms',
      'Description Information',
      'Dates of Existence',
      'Contact Details',
      'External Documents'
    ]
  end

  def expect_sidebar_items(agent_type, expected_items, unexpected_items = [])
    visit "/agents/#{agent_type}/required"
    sidebar = find('#archivesSpaceSidebar')

    expected_items.each do |item|
      expect(sidebar).to have_link(item)
    end

    unexpected_items.each do |item|
      expect(sidebar).not_to have_link(item)
    end
  end

  def expect_form_sections(agent_type, expected_items, unexpected_items = [])
    visit "/agents/#{agent_type}/required"

    expected_items.each do |item|
      expect(page).to have_selector('h3, h4', text: item)
    end

    unexpected_items.each do |item|
      expect(page).not_to have_selector('h3, h4', text: item)
    end
  end

  shared_examples 'agent sidebar items' do |agent_type, unexpected_items|
    it "shows the correct items for #{agent_type}" do
      expected_items = all_possible_items - unexpected_items
      expect_sidebar_items(agent_type, expected_items, unexpected_items)
    end
  end

  shared_examples 'light mode agent sidebar items' do |agent_type, additional_items = []|
    it "shows the correct items for #{agent_type} in light mode" do
      visit "/agents/#{agent_type}/required"
      check 'Light Mode'

      expected_items = light_mode_common_items + additional_items
      sidebar = find('#archivesSpaceSidebar')

      expected_items.each do |item|
        expect(sidebar).to have_link(item)
      end

      (all_possible_items - expected_items).each do |item|
        expect(sidebar).not_to have_link(item)
      end
    end
  end

  shared_examples 'agent form sections' do |agent_type, unexpected_items|
    it "shows the correct form sections for #{agent_type}" do
      expected_items = all_possible_items - unexpected_items
      expect_form_sections(agent_type, expected_items, unexpected_items)
    end
  end

  shared_examples 'light mode agent form sections' do |agent_type, additional_items = []|
    it "shows the correct form sections for #{agent_type} in light mode" do
      visit "/agents/#{agent_type}/required"
      check 'Light Mode'
      expected_items = light_mode_common_items + additional_items
      expected_items.each do |item|
        expect(page).to have_selector('h3, h4', text: item)
      end

      (all_possible_items - expected_items).each do |item|
        expect(page).not_to have_selector('h3, h4', text: item)
      end
    end
  end

  context 'when lightmode is off' do
    describe 'the sidebar' do
      include_examples 'agent sidebar items', 'agent_person', []
      include_examples 'agent sidebar items', 'agent_family', ['Genders']
      include_examples 'agent sidebar items', 'agent_corporate_entity', ['Genders']
      include_examples 'agent sidebar items', 'agent_software', [
        'Record Control Information',
        'Record IDs',
        'Record Info',
        'Other Agency Codes',
        'Convention Declarations',
        'Metadata Rights Declarations',
        'Maintenance History',
        'Sources',
        'Alternate Sets',
        'Genders',
        'Relation Information',
        'Related External Resources'
      ]
    end

    describe 'the form' do
      include_examples 'agent form sections', 'agent_person', []
      include_examples 'agent form sections', 'agent_family', ['Genders']
      include_examples 'agent form sections', 'agent_corporate_entity', ['Genders']
      include_examples 'agent form sections', 'agent_software', [
        'Record Control Information',
        'Record IDs',
        'Record Info',
        'Other Agency Codes',
        'Convention Declarations',
        'Metadata Rights Declarations',
        'Maintenance History',
        'Sources',
        'Alternate Sets',
        'Genders',
        'Relation Information',
        'Related External Resources'
      ]
    end
  end

  context 'when lightmode is on' do
    describe 'the sidebar' do
      include_examples 'light mode agent sidebar items', 'agent_person', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent sidebar items', 'agent_family', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent sidebar items', 'agent_corporate_entity', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent sidebar items', 'agent_software'
    end

    describe 'the form' do
      include_examples 'light mode agent form sections', 'agent_person', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent form sections', 'agent_family', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent form sections', 'agent_corporate_entity', [
        'Record Control Information',
        'Record IDs',
        'Relation Information'
      ]
      include_examples 'light mode agent form sections', 'agent_software'
    end
  end
end
