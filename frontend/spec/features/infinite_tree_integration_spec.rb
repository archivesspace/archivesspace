# frozen_string_literal: true

# Integration spec for Infinite Tree components (Router + Tree + Record Pane)

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Integration', js: true do
  include_context 'infinite tree integration setup'

  let(:show_path) { "/resources/#{resource.id}" }
  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:ao_hash) { "#tree::archival_object_#{ao.id}" }

  describe 'on initial load' do
    context 'when the URL has no record hash' do
      it_behaves_like 'adds root hash and displays root on load', :show_path, :show
      it_behaves_like 'adds root hash and displays root on load', :edit_path, :edit
    end

    context 'when the URL has a valid record hash' do
      it_behaves_like 'keeps hash and displays record on load',
        :show_path, :root_hash, :resource, :show
      it_behaves_like 'keeps hash and displays record on load',
        :edit_path, :root_hash, :resource, :edit, '#form_resource'
      it_behaves_like 'keeps hash and displays record on load',
        :show_path, :ao_hash, :ao, :show
      it_behaves_like 'keeps hash and displays record on load',
        :edit_path, :ao_hash, :ao, :edit, '#form_archival_object'
    end

    context 'when the URL has a hash for a non-existent record' do
      it 'displays the tree root and Record Not Found in the pane' do
        nonexistent_id = ao.id + 999
        visit "#{show_path}#tree::archival_object_#{nonexistent_id}"
        wait_for_ajax

        aggregate_failures do
          expect(page).to have_css('#infinite-tree-container .root')
          expect(page).not_to have_css('#infinite-tree-container .selected')
          within('#infinite-tree-record-pane') do
            expect(page).to have_css('h2', text: 'Record Not Found')
            expect(page).to have_text("The record you've tried to access may no longer exist or you may not have permission to view it.")
          end
        end
      end
    end
  end

  describe 'when navigating with no unsaved changes' do
    context 'via tree node click' do
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
        :show_path, :root_hash, :resource, :ao, :ao_hash, :show
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
        :show_path, :ao_hash, :ao, :resource, :root_hash, :show
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
        :edit_path, :root_hash, :resource, :ao, :ao_hash, :edit, '#form_archival_object'
      it_behaves_like 'tree node title click updates pane and URL when no unsaved changes',
        :edit_path, :ao_hash, :ao, :resource, :root_hash, :edit, '#form_resource'
    end

    context 'via record hash change' do
      it 'updates the pane and URL to the target record' do
        visit "#{edit_path}#{root_hash}"
        wait_for_ajax

        page.execute_script("window.location.hash = 'tree::archival_object_#{ao.id}'")
        wait_for_ajax

        aggregate_failures do
          expect(page.current_url).to match(%r{#{ao_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: ao.title) }
        end
      end
    end
  end

  describe 'when navigating with unsaved changes' do
    it 'guard shows modal on hash change and reverts the hash' do
      visit "#{edit_path}#{ao_hash}"
      wait_for_ajax
      fill_in 'archival_object_component_id_', with: 'unsaved change'
      wait_for_ajax

      page.execute_script("window.location.hash = 'tree::resource_#{resource.id}'")
      wait_for_ajax

      aggregate_failures do
        expect(page).to have_css('#saveYourChangesModal', visible: true)
        expect(page.current_url).to match(%r{#{ao_hash}})

        within('#saveYourChangesModal') { click_on 'Cancel' }
        expect(page).not_to have_css('#saveYourChangesModal', visible: true)
      end
    end

    it 'guard shows modal on tree title click' do
      visit "#{edit_path}#{ao_hash}"
      wait_for_ajax
      fill_in 'archival_object_component_id_', with: 'unsaved change'
      wait_for_ajax

      within('#infinite-tree-container') { click_link resource.title }
      wait_for_ajax

      expect(page).to have_css('#saveYourChangesModal', visible: true)
      within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: ao.title) }
    end

    describe 'modal actions' do
      it 'Save submits form, closes modal, and navigates to new record' do
        visit "#{edit_path}#{ao_hash}"
        wait_for_ajax
        fill_in 'archival_object_component_id_', with: 'updated component id'
        wait_for_ajax
        within('#infinite-tree-container') { click_link resource.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Save Changes' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: resource.title) }
        end
      end

      it 'Dismiss discards changes, closes modal, and navigates to new record' do
        visit "#{edit_path}#{ao_hash}"
        wait_for_ajax
        fill_in 'archival_object_component_id_', with: 'unsaved change'
        wait_for_ajax
        within('#infinite-tree-container') { click_link resource.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Dismiss Changes' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{root_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: resource.title) }
        end
      end

      it 'Cancel closes modal and stays on current record' do
        visit "#{edit_path}#{ao_hash}"
        wait_for_ajax
        fill_in 'archival_object_component_id_', with: 'unsaved change'
        wait_for_ajax
        within('#infinite-tree-container') { click_link resource.title }
        wait_for_ajax

        within('#saveYourChangesModal') { click_on 'Cancel' }
        wait_for_ajax

        aggregate_failures do
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          expect(page.current_url).to match(%r{#{ao_hash}})
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: ao.title) }
        end
      end
    end

    context 'Add Child from toolbar (resource)' do
      it 'loads new archival object form and Cancel returns to resource edit' do
        visit "#{edit_path}#{root_hash}"
        wait_for_ajax

        find('.js-itree-toolbar-add-child').click
        wait_for_ajax

        aggregate_failures do
          within('#infinite-tree-container') do
            expect(page).to have_css('li#archival_object_new.js-itree-synthetic-new.selected')
          end
          within('#infinite-tree-record-pane') do
            expect(page).to have_css('#archival_object_form')
            expect(page).to have_button('Save Archival Object', match: :first)
          end
          expect(page.current_url).to match(%r{#{Regexp.escape(root_hash)}})
        end

        within('#infinite-tree-record-pane') { find('.btn-cancel').click }
        wait_for_ajax

        aggregate_failures do
          within('#infinite-tree-record-pane') do
            expect(page).to have_css('#form_resource')
            expect(page).to have_css('h2', text: resource.title)
          end
          expect(page.current_url).to match(%r{#{Regexp.escape(root_hash)}})
        end
      end
    end

    context 'after successful save' do
      it 'form has no unsaved changes; navigation proceeds without modal' do
        visit "#{edit_path}#{ao_hash}"
        wait_for_ajax

        fill_in 'archival_object_title_', with: "Updated Title #{now}"
        within('#infinite-tree-container') { click_link resource.title }
        wait_for_ajax

        aggregate_failures do
          expect(page).to have_css('#saveYourChangesModal', visible: true)
          within('#saveYourChangesModal') { click_on 'Cancel' }

          find('button', text: 'Save Archival Object', match: :first).click
          wait_for_ajax
          expect(page).to have_text("Archival Object Updated Title #{now} updated")

          within('#infinite-tree-container') { click_link resource.title }
          wait_for_ajax
          expect(page).not_to have_css('#saveYourChangesModal', visible: true)
          within('#infinite-tree-record-pane') { expect(page).to have_css('h2', text: resource.title) }
        end
      end
    end
  end
end
