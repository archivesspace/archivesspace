# frozen_string_literal: true

# Integration spec for Tree components (Router + Tree + Record Pane)

require 'spec_helper'
require 'rails_helper'

describe 'Tree Integration', js: true do
  context 'Resources' do
    include_context 'tree integration setup'

    let(:show_path) { "/resources/#{resource.id}" }
    let(:edit_path) { "/resources/#{resource.id}/edit" }
    let(:root_hash) { "#tree::resource_#{resource.id}" }
    let(:ao_hash) { child_record_hash }

    describe 'show view' do
      describe 'on initial load' do
        context 'when the URL has no record hash' do
          it_behaves_like 'adds root hash and displays root on load', :show_path, :show
        end

        context 'when the URL has a valid record hash' do
          it_behaves_like 'keeps hash and displays record on load',
                          :show_path, :root_hash, :resource, :show
          it_behaves_like 'keeps hash and displays record on load',
                          :show_path, :ao_hash, :ao, :show
        end

        context 'when the URL has a hash for a non-existent record' do
          it 'displays the tree root and Record Not Found in the pane' do
            nonexistent_id = ao.id + 999
            visit "#{show_path}#tree::archival_object_#{nonexistent_id}"
            expect(page).to have_css('#tree-record-pane h2', text: 'Record Not Found')

            aggregate_failures do
              expect(page).to have_css('#tree-container .root')
              expect(page).not_to have_css(
                '#tree-container .current',
                visible: :all
              )
              within('#tree-record-pane') do
                expect(page).to have_css('h2', text: 'Record Not Found')
                expect(page).to have_text(
                  "The record you've tried to access may no longer exist or you may not have permission to view it."
                )
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
        end
      end
    end

    describe 'edit view' do
      it_behaves_like 'navigating the edit view with integrated router and pane',
                      TreeHierarchyConfigs::INTEGRATION[:resources]
    end

    describe 'inline create after save' do
      context 'consecutive inline create after Save' do
        it 'Add Duplicate uses the saved node as anchor on the second create without re-selection' do
          visit "#{edit_path}#{ao_hash}"
          wait_for_tree_loaded

          find('.js-tree-toolbar-add-duplicate').click
          expect(page).to have_css('.alert.alert-success.with-hide-alert', text: /duplicated from/)

          duplicate_title = "[Duplicated] First AO #{now}"
          fill_in 'archival_object_title_', with: duplicate_title

          wait_for_tree_record_pane_submit { find('button', text: 'Save Archival Object', match: :first).click }

          saved_id = within('#tree-record-pane') do
            find('#uri', visible: :all).value.split('/').last.to_i
          end

          aggregate_failures 'saved record is current in tree' do
            expect(page).to have_css(
              "#tree-container li#archival_object_#{saved_id}.current",
              visible: :all
            )
          end

          find('.js-tree-toolbar-add-duplicate').click
          expect(page).to have_css('.alert.alert-success.with-hide-alert', text: /duplicated from/)

          aggregate_failures do
            within('#tree-container') do
              expect(page).to have_css(
                "#tree-container li#archival_object_#{saved_id} + li#archival_object_new"
              )
              expect(page).to have_no_css(
                "#tree-container li#archival_object_#{ao.id} + li#archival_object_new"
              )
              expect(page).to have_css(
                '.record-title',
                text: I18n.t('archival_object._frontend.tree.duplicated_record_title')
              )
            end
            expect(page.current_url).to include('#new')
            within('#tree-record-pane') do
              expect(page).to have_css('#archival_object_form')
              expect(page).to have_css(
                '.alert.alert-success.with-hide-alert',
                text: /duplicated from/
              )
            end
          end
        end
      end
    end
  end

  context 'Digital Objects' do
    it_behaves_like 'navigating the edit view with integrated router and pane',
                    TreeHierarchyConfigs::INTEGRATION[:digital_objects]
  end

  context 'Classifications' do
    it_behaves_like 'navigating the edit view with integrated router and pane',
                    TreeHierarchyConfigs::INTEGRATION[:classifications]
  end
end
