# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree digital object spawn from instance linker', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:resource_hash) { "#tree::resource_#{resource.id}" }
  let(:ao_hash) { "#tree::archival_object_#{ao.id}" }

  before do
    enable_digital_object_spawn_preference!
  end

  def enable_digital_object_spawn_preference!
    visit "/preferences/#{repo.id}/edit"

    element = find('#preference_defaults__digital_object_spawn_')
    element.click unless element.checked?

    click_on 'Save Preferences'
    expect(page).to have_text 'Preferences updated'
  end

  def open_spawned_digital_object_create_modal(linker_scope:, modal_id:)
    within '#infinite-tree-record-pane' do
      click_on 'Add Digital Object'

      within linker_scope do
        find('.dropdown-toggle').click
        click_on 'Create'
      end
    end

    within modal_id do
      yield
    end
  end

  it 'prefills the create form from the resource selected in the tree' do
    visit "#{edit_path}#{resource_hash}"
    wait_for_infinite_tree_pane_ready

    aggregate_failures 'tree and pane show the resource' do
      expect(page).to have_css(infinite_tree_current_node_selector(resource))
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('#resource_form')
        expect(page).to have_css('h2', text: resource.title)
      end
    end

    open_spawned_digital_object_create_modal(
      linker_scope: "div[data-id-path='resource_instances__0__digital_object_']",
      modal_id: '#resource_instances__0__digital_object__ref__modal'
    ) do
      expect(page).to have_field('digital_object_title_', with: resource.title)
      expect(page).not_to have_field('digital_object_title_', with: ao.title)
    end
  end

  it 'prefills the create form from the archival object selected in the tree' do
    visit "#{edit_path}#{ao_hash}"
    wait_for_infinite_tree_pane_ready

    aggregate_failures 'tree and pane show the archival object' do
      expect(page).to have_css(infinite_tree_current_node_selector(ao))
      within('#infinite-tree-record-pane') do
        expect(page).to have_css('#archival_object_form')
        expect(page).to have_css('h2', text: ao.title)
      end
    end

    open_spawned_digital_object_create_modal(
      linker_scope: "div[data-id-path='archival_object_instances__0__digital_object_']",
      modal_id: '#archival_object_instances__0__digital_object__ref__modal'
    ) do
      expect(page).to have_field('digital_object_title_', with: ao.title)
      expect(page).not_to have_field('digital_object_title_', with: resource.title)
    end
  end
end
