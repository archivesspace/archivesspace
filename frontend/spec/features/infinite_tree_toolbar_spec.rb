# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Toolbar', js: true do
  include_context 'infinite tree integration setup'

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Second AO #{now}"
    )
  end

  let!(:ao3) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Third AO #{now}"
    )
  end

  let(:show_path) { "/resources/#{resource.id}" }
  let(:edit_path) { "#{show_path}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:ao_hash) { "#tree::archival_object_#{ao.id}" }

  shared_examples 'showing the Record Pane' do
    it 'shows the Record Pane with the expected title' do
      expect(page).to have_css('#infinite-tree-record-pane h2', text: expected_title)
    end
  end

  shared_examples 'hiding the Record Pane' do
    it 'hides the Record Pane' do
      expect(page).to have_css('#infinite-tree-record-pane', visible: :hidden)
    end
  end

  context 'show view' do
    before do
      visit show_path
      wait_for_ajax
    end

    it 'is not present' do
      expect(page).to have_css('#infinite-tree-component')
      expect(page).not_to have_css('#infinite-tree-toolbar')
    end
  end

  context 'edit view' do
    describe 'initial state' do
      context 'when the root node is the current record' do
        before do
          visit edit_path
          wait_for_ajax
        end

        context 'default mode' do
          it 'provides the default root controls' do
            within '#infinite-tree-toolbar' do
              aggregate_failures do
                expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.enable_reorder'))
                expect(page).to have_css('.js-itree-toolbar-expand-mode', text: I18n.t('actions.expand_tree_mode_on'))
                expect(page).to have_css('.js-itree-toolbar-collapse-tree', text: I18n.t('actions.collapse_tree'))
                expect(page).to have_css('.js-itree-toolbar-add-child', text: I18n.t('resource._frontend.action.add_child'))
                expect(page).to have_css('.js-itree-toolbar-load-bulk', text: I18n.t('resource._frontend.action.load_bulk'))
                expect(page).to have_css('#load_via_spreadsheet_help_icon')
                expect(page).to have_css('.js-itree-toolbar-rde', text: I18n.t('actions.rapid_data_entry'))
                expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))

                expect(page).to have_css('.js-itree-toolbar-cut', visible: :hidden, text: I18n.t('actions.cut'))
                expect(page).to have_css('.js-itree-toolbar-paste', visible: :hidden, text: I18n.t('actions.paste'))
                expect(page).to have_css('.js-itree-toolbar-move-toggle', visible: :hidden, text: I18n.t('actions.move'))
                expect(page).to have_css('.js-itree-toolbar-add-sibling', visible: :hidden, text: I18n.t('archival_object._frontend.action.add_sibling'))
                expect(page).to have_css('.js-itree-toolbar-add-duplicate', visible: :hidden, text: I18n.t('archival_object._frontend.action.add_duplicate'))
              end
            end
          end

          let(:expected_title) { resource.title }

          it_behaves_like 'showing the Record Pane'
        end

        context 'reorder mode' do
          before { enable_reorder_mode }

          it 'provides the reorder root controls with Cut, Paste, and Move disabled' do
            within '#infinite-tree-toolbar' do
              aggregate_failures do
                expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.reorder_active'))
                expect(page).to have_css('.js-itree-toolbar-cut.disabled[disabled]')
                expect(page).to have_css('.js-itree-toolbar-paste.disabled[disabled]')
                expect(page).to have_css('.js-itree-toolbar-move-toggle.disabled[disabled]')
                expect(page).to have_css('.js-itree-toolbar-finish-editing')

                expect(page).to have_css('.js-itree-toolbar-expand-mode', visible: :hidden)
                expect(page).to have_css('.js-itree-toolbar-collapse-tree', visible: :hidden)
                expect(page).to have_css('.js-itree-toolbar-add-child', visible: :hidden)
                expect(page).to have_css('.js-itree-toolbar-load-bulk', visible: :hidden)
                expect(page).to have_css('#load_via_spreadsheet_help_icon', visible: :hidden)
                expect(page).to have_css('.js-itree-toolbar-rde', visible: :hidden)
              end
            end
          end

          it_behaves_like 'hiding the Record Pane'
        end
      end

      context 'when a child node is the current record' do
        before do
          visit "#{edit_path}#{ao_hash}"
          wait_for_ajax
        end

        context 'default mode' do
          it 'provides the default root controls plus Add Sibling and Add Duplicate' do
            within '#infinite-tree-toolbar' do
              aggregate_failures do
                expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.enable_reorder'))
                expect(page).to have_css('.js-itree-toolbar-expand-mode', text: I18n.t('actions.expand_tree_mode_on'))
                expect(page).to have_css('.js-itree-toolbar-collapse-tree', text: I18n.t('actions.collapse_tree'))
                expect(page).to have_css('.js-itree-toolbar-add-child', text: I18n.t('resource._frontend.action.add_child'))
                expect(page).to have_css('.js-itree-toolbar-add-sibling', text: I18n.t('archival_object._frontend.action.add_sibling'))
                expect(page).to have_css('.js-itree-toolbar-add-duplicate', text: I18n.t('archival_object._frontend.action.add_duplicate'))
                expect(page).to have_css('.js-itree-toolbar-load-bulk', text: I18n.t('resource._frontend.action.load_bulk'))
                expect(page).to have_css('#load_via_spreadsheet_help_icon')
                expect(page).to have_css('.js-itree-toolbar-rde', text: I18n.t('actions.rapid_data_entry'))
                expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))

                expect(page).to have_css('.js-itree-toolbar-cut', visible: :hidden, text: I18n.t('actions.cut'))
                expect(page).to have_css('.js-itree-toolbar-paste', visible: :hidden, text: I18n.t('actions.paste'))
                expect(page).to have_css('.js-itree-toolbar-move-toggle', visible: :hidden, text: I18n.t('actions.move'))
              end
            end
          end

          let(:expected_title) { ao.title }

          it_behaves_like 'showing the Record Pane'
        end

        context 'reorder mode' do
          before { enable_reorder_mode }

          it 'provides the reorder root controls but with Cut and Move enabled' do
            within '#infinite-tree-toolbar' do
              aggregate_failures do
                expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.reorder_active'))
                expect(page).to have_css('.js-itree-toolbar-cut:not(.disabled[disabled])')
                expect(page).to have_css('.js-itree-toolbar-paste.disabled[disabled]')
                expect(page).to have_css('.js-itree-toolbar-move-toggle:not(.disabled[disabled])')
              end
            end
          end

          it_behaves_like 'hiding the Record Pane'
        end
      end
    end

    describe 'default mode' do
      describe 'expand and collapse tree controls' do
        let!(:ao_child_01) do
          create(:archival_object, resource: { 'ref' => resource.uri }, title: "Child 01 #{now}")
        end
        let!(:ao_child_01_child_01) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_01.uri },
            title: "Child 01 Child 01 #{now}"
          )
        end
        let!(:ao_child_01_child_02) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_01.uri },
            title: "Child 01 Child 02 #{now}"
          )
        end
        let!(:ao_child_01_child_02_child_02) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_01_child_02.uri },
            title: "Child 01 Child 02 Child 02 #{now}"
          )
        end
        let!(:ao_deep_leaf) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_01_child_02_child_02.uri },
            title: "Child 01 Child 02 Child 02 Child 01 Child 01 #{now}"
          )
        end
        let!(:ao_child_02) do
          create(:archival_object, resource: { 'ref' => resource.uri }, title: "Child 02 #{now}")
        end
        let!(:ao_child_02_child_01) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_02.uri },
            title: "Child 02 Child 01 #{now}"
          )
        end
        let!(:ao_child_02_child_01_child_01) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao_child_02_child_01.uri },
            title: "Child 02 Child 01 Child 01 #{now}"
          )
        end
        let!(:ao_child_03) do
          create(:archival_object, resource: { 'ref' => resource.uri }, title: "Child 03 #{now}")
        end
        let(:parent_count) { 5 }
        let(:expand_mode_toggle_button) { find('.js-itree-toolbar-expand-mode') }
        let(:collapse_tree_button) { find('.js-itree-toolbar-collapse-tree') }
        let(:parent_selector_base) { 'li.node:not(.root)' }
        let(:collapsed_parent_selector) { "#{parent_selector_base}[aria-expanded='false']" }
        let(:expanded_parent_selector) { "#{parent_selector_base}[aria-expanded='true']" }
        let(:parent_expand_button_selector) { "#{parent_selector_base} > .node-row .node-expand" }
        let(:disabled_parent_expand_button_selector) { "#{parent_expand_button_selector}.disabled" }
        let(:enabled_parent_expand_button_selector) { "#{parent_expand_button_selector}:not(.disabled)" }

        before do
          visit edit_path
          wait_for_ajax
        end

        context 'auto-expand mode' do
          before do
            expect(page).to have_no_css('#infinite-tree-container.expand-all')
            expect(page).to have_css('.js-itree-toolbar-expand-mode', exact_text: I18n.t('actions.expand_tree_mode_on'))
            expect(page).to have_no_css(expanded_parent_selector)
          end

          it 'expands, and disables the expand buttons for, all parent nodes in and near the viewport' do
            expand_mode_toggle_button.click

            aggregate_failures do
              expect(page).to have_css('#infinite-tree-container.expand-all')
              expect(page).to have_css('.js-itree-toolbar-expand-mode', exact_text: I18n.t('actions.expand_tree_mode_off'))
              expect(page).to have_css(expanded_parent_selector, count: parent_count)
              expect(page).to have_css(disabled_parent_expand_button_selector, count: parent_count)
              expect(page).to have_css("#archival_object_#{ao_child_01_child_01.id}", visible: :visible)
              expect(page).to have_css("#archival_object_#{ao_child_02_child_01_child_01.id}", visible: :visible)
              expect(page).to have_css("#archival_object_#{ao_deep_leaf.id}", visible: :visible)
            end
          end

          context 'root records with many children' do
            let(:edit_path) { "/resources/#{scroll_resource.id}/edit" }
            let(:scroll_resource) { create(:resource, title: "Scroll Expand Resource #{now}") }
            let(:total_root_children) { 152 }
            let(:first_root_child) { scroll_root_children[0] }
            let(:second_root_child) { scroll_root_children[1] }
            let(:scroll_trigger_child) { scroll_root_children[129] } # "Scroll Root Child 130 ..."
            let(:penultimate_root_child) { scroll_root_children[150] }
            let(:last_root_child) { scroll_root_children[151] }
            let(:root_child_selector) { '#infinite-tree-container .root.node > .node-children > li.node.indent-level-1' }
            let!(:scroll_root_children) do
              Array.new(total_root_children) do |i|
                create(
                  :archival_object,
                  resource: { 'ref' => scroll_resource.uri },
                  title: "Scroll Root Child #{i + 1} #{now}"
                )
              end
            end
            let!(:scroll_nested_chains) do
              [0, 1, total_root_children - 2, total_root_children - 1].map do |idx|
                child = create(
                  :archival_object,
                  resource: { 'ref' => scroll_resource.uri },
                  parent: { 'ref' => scroll_root_children[idx].uri },
                  title: "Scroll Root Child #{idx + 1} Child #{now}"
                )

                create(
                  :archival_object,
                  resource: { 'ref' => scroll_resource.uri },
                  parent: { 'ref' => child.uri },
                  title: "Scroll Root Child #{idx + 1} Child Child #{now}"
                )
              end
            end

            before do
              scroll_root_children
              scroll_nested_chains
              visit edit_path
              wait_for_ajax
            end

            it 'expands parent nodes that are far away when the user scrolls close to them' do
              expect(page).to have_css('.root.node > .node-children[data-total-child-batches="6"]')
              expect(page).to have_css(root_child_selector, count: 30)

              tree_container = find('#infinite-tree-container')
              (1..5).each do |offset|
                observer_node = find("[data-observe-offset='#{offset}']", visible: :all)
                tree_container.scroll_to(observer_node, align: :center)
                wait_for_ajax
              end

              expect(page).to have_css(root_child_selector, count: total_root_children)

              tree_container.scroll_to(find('#infinite-tree-container .root.node > .node-row'), align: :top)
              wait_for_ajax

              expand_mode_toggle_button.click
              expect(page).to have_css('#infinite-tree-container.expand-all')
              expect(page).to have_css("#archival_object_#{first_root_child.id}[aria-expanded='true']")
              expect(page).to have_css("#archival_object_#{second_root_child.id}[aria-expanded='true']")
              expect(page).to have_css("#archival_object_#{penultimate_root_child.id}[aria-expanded='false']")
              expect(page).to have_css("#archival_object_#{last_root_child.id}[aria-expanded='false']")

              tree_container.scroll_to(find("#archival_object_#{scroll_trigger_child.id}", visible: :all), align: :center)
              wait_for_ajax

              expect(page).to have_css("#archival_object_#{penultimate_root_child.id}[aria-expanded='true']")
              expect(page).to have_css("#archival_object_#{last_root_child.id}[aria-expanded='true']")
            end
          end

          context 'when toggled off' do
            before do
              expand_mode_toggle_button.click
              expect(page).to have_css('.js-itree-toolbar-expand-mode.btn-success')

              # Hack around flakiness experienced when using `expand_mode_toggle_button.click`
              within '#infinite-tree-toolbar' do
                click_button 'Disable Auto-Expand'
                wait_for_ajax
              end

              expect(page).to have_css('.js-itree-toolbar-expand-mode.btn-default')
            end

            it 're-enables the expand buttons for all expanded parent nodes in the tree' do
              aggregate_failures do
                expect(page).to have_css('#infinite-tree-container:not(.expand-all)')
                expect(page).to have_css('.js-itree-toolbar-expand-mode', exact_text: I18n.t('actions.expand_tree_mode_on'))
                expect(page).to have_css(expanded_parent_selector, count: parent_count)
                expect(page).to have_css(enabled_parent_expand_button_selector, count: parent_count)
                expect(page).to have_css("#archival_object_#{ao_child_01_child_01.id}", visible: :visible)
                expect(page).to have_css("#archival_object_#{ao_child_02_child_01_child_01.id}", visible: :visible)
                expect(page).to have_css("#archival_object_#{ao_deep_leaf.id}", visible: :visible)
              end
            end
          end
        end

        describe 'collapse tree behavior' do
          before do
            expand_mode_toggle_button.click
            wait_for_ajax
          end

          it 'collapses all expanded parent nodes and turns off auto-expand mode if it is on' do
            expect(page).to have_css('.js-itree-toolbar-expand-mode.btn-success')

            collapse_tree_button.click

            aggregate_failures do
              expect(page).to have_css('#infinite-tree-container:not(.expand-all)')
              expect(page).to have_css('.js-itree-toolbar-expand-mode', exact_text: I18n.t('actions.expand_tree_mode_on'))
              expect(page).to have_no_css('.js-itree-toolbar-expand-mode.btn-success')
              expect(page).to have_css(collapsed_parent_selector, visible: :all, count: parent_count)
              expect(page).to have_css("#archival_object_#{ao_child_01_child_01.id}", visible: false)
              expect(page).to have_css("#archival_object_#{ao_child_02_child_01_child_01.id}", visible: false)
              expect(page).to have_css("#archival_object_#{ao_deep_leaf.id}", visible: false)
            end
          end
        end
      end

      describe 'record creation controls' do
        describe 'Add Child' do
          context 'from the root record' do
            before do
              visit "#{edit_path}#{root_hash}"
              wait_for_infinite_tree_inline_edit_form(form_prefix: root_form_prefix)
            end

            it 'opens a new child record form with a synthetic tree row' do
              click_infinite_tree_toolbar_add_child

              aggregate_failures do
                within('#infinite-tree-container') do
                  expect(page).to have_css("li##{child_form_prefix}_new.js-itree-synthetic-new.current")
                end
                within('#infinite-tree-record-pane') do
                  expect(page).to have_css("##{child_form_prefix}_form")
                  expect(page).to have_button(
                    I18n.t("#{child_form_prefix}._frontend.action.save"),
                    match: :first
                  )
                end
                expect(page.current_url).to include('#new')
              end
            end

            it 'shows the created flash message after Save' do
              click_infinite_tree_toolbar_add_child

              title = "New Child #{now}"
              fill_and_save_new_child_record(
                title: title,
                form_prefix: child_form_prefix,
                level: 'Item'
              )

              expect(page).to have_css(
                '.alert.alert-success.with-hide-alert',
                text: "Archival Object #{title} on Resource #{root_record.title} created"
              )
            end

            it 'returns to the anchor record edit when Cancel is clicked' do
              click_infinite_tree_toolbar_add_child
              cancel_infinite_tree_record_pane_form

              aggregate_failures do
                within('#infinite-tree-record-pane') do
                  expect(page).to have_css("#form_#{root_form_prefix}")
                  expect(page).to have_css('h2', text: root_record.title)
                end
                expect(page.current_url).to match(%r{#{Regexp.escape(root_hash)}})
                expect(page).to have_css(
                  infinite_tree_current_node_selector(root_record),
                  visible: :all
                )
              end
            end
          end

          context 'from a child record' do
            before do
              nested_child_record
              visit "#{edit_path}#{nested_child_record_hash}"
              wait_for_ajax
            end

            it 'opens a new child record form with a synthetic tree row' do
              click_infinite_tree_toolbar_add_child

              aggregate_failures do
                within('#infinite-tree-container') do
                  expect(page).to have_css(
                    "li##{child_form_prefix}_new.js-itree-synthetic-new.current.indent-level-3"
                  )
                  expect(page).to have_css('ol.node-children[data-tree-level="3"]')
                end
                within('#infinite-tree-record-pane') do
                  expect(page).to have_css("##{child_form_prefix}_form")
                  expect(page).to have_button(
                    I18n.t("#{child_form_prefix}._frontend.action.save"),
                    match: :first
                  )
                end
                expect(page.current_url).to include('#new')
              end
            end

            it 'shows the created flash message after Save' do
              click_infinite_tree_toolbar_add_child

              title = "New Nested Child #{now}"
              fill_and_save_new_child_record(
                title: title,
                form_prefix: child_form_prefix,
                level: 'Item'
              )

              expect(page).to have_css(
                '.alert.alert-success.with-hide-alert',
                text: "Archival Object #{title} created as child of #{nested_child_record.title} on Resource #{root_record.title}"
              )
            end

            it 'returns to the anchor record edit when Cancel is clicked' do
              click_infinite_tree_toolbar_add_child
              cancel_infinite_tree_record_pane_form

              aggregate_failures do
                within('#infinite-tree-record-pane') do
                  expect(page).to have_css("#form_#{child_form_prefix}")
                  expect(page).to have_css('h2', text: nested_child_record.title)
                end
                expect(page.current_url).to match(%r{#{Regexp.escape(nested_child_record_hash)}})
                expect(page).to have_css(
                  infinite_tree_current_node_selector(nested_child_record),
                  visible: :all
                )
              end
            end
          end
        end

        describe 'Add Sibling' do
          before do
            visit "#{edit_path}#{child_record_hash}"
            wait_for_ajax
          end

          it 'opens a new child record form with a synthetic tree row' do
            click_infinite_tree_toolbar_add_sibling

            aggregate_failures do
              within('#infinite-tree-container') do
                expect(page).to have_css(
                  "li##{child_form_prefix}_new.js-itree-synthetic-new.current.indent-level-1"
                )
                expect(page).to have_css(
                  "#infinite-tree-container li##{infinite_tree_node_id_for(child_record)} + li##{child_form_prefix}_new"
                )
              end
              within('#infinite-tree-record-pane') do
                expect(page).to have_css("##{child_form_prefix}_form")
                expect(page).to have_button(
                  I18n.t("#{child_form_prefix}._frontend.action.save"),
                  match: :first
                )
              end
              expect(page.current_url).to include('#new')
            end
          end

          it 'shows the created flash message after Save' do
            click_infinite_tree_toolbar_add_sibling

            title = "New Sibling #{now}"
            fill_and_save_new_child_record(
              title: title,
              form_prefix: child_form_prefix,
              level: 'Item'
            )

            expect(page).to have_css(
              '.alert.alert-success.with-hide-alert',
              text: "Archival Object #{title} on Resource #{root_record.title} created"
            )
          end

          it 'returns to the anchor record edit when Cancel is clicked' do
            click_infinite_tree_toolbar_add_sibling
            cancel_infinite_tree_record_pane_form

            aggregate_failures do
              within('#infinite-tree-record-pane') do
                expect(page).to have_css("#form_#{child_form_prefix}")
                expect(page).to have_css('h2', text: child_record.title)
              end
              expect(page.current_url).to match(%r{#{Regexp.escape(child_record_hash)}})
              expect(page).to have_css(
                infinite_tree_current_node_selector(child_record),
                visible: :all
              )
            end
          end
        end

        describe 'Add Duplicate' do
          before do
            visit "#{edit_path}#{child_record_hash}"
            wait_for_ajax
          end

          it 'opens a new child record form with a synthetic tree row' do
            click_infinite_tree_toolbar_add_duplicate

            aggregate_failures do
              within('#infinite-tree-container') do
                expect(page).to have_css(
                  "li##{child_form_prefix}_new.js-itree-synthetic-new.current.indent-level-1"
                )
                expect(page).to have_css(
                  "#infinite-tree-container li##{infinite_tree_node_id_for(child_record)} + li##{child_form_prefix}_new"
                )
                expect(page).to have_css(
                  '.record-title',
                  text: I18n.t("#{child_form_prefix}._frontend.tree.duplicated_record_title")
                )
              end
              within('#infinite-tree-record-pane') do
                expect(page).to have_css("##{child_form_prefix}_form")
                expect(page).to have_button(
                  I18n.t("#{child_form_prefix}._frontend.action.save"),
                  match: :first
                )
              end
              expect(page.current_url).to include('#new')
            end
          end

          it 'shows the duplicated-from flash and the created flash after Save' do
            nested_child_record
            visit "#{edit_path}#{nested_child_record_hash}"
            wait_for_ajax

            click_infinite_tree_toolbar_add_duplicate

            expect(page).to have_css(
              '.alert.alert-success.with-hide-alert',
              text: /duplicated from/
            )

            title = "[Duplicated] #{nested_child_record.title}"
            fill_and_save_new_child_record(title: title, form_prefix: child_form_prefix)

            expect(page).to have_css(
              '.alert.alert-success.with-hide-alert',
              text: "Archival Object #{title} created as child of #{child_record.title} on Resource #{root_record.title}"
            )
          end

          it 'returns to the anchor record edit when Cancel is clicked' do
            click_infinite_tree_toolbar_add_duplicate
            cancel_infinite_tree_record_pane_form

            aggregate_failures do
              within('#infinite-tree-record-pane') do
                expect(page).to have_css("#form_#{child_form_prefix}")
                expect(page).to have_css('h2', text: child_record.title)
              end
              expect(page.current_url).to match(%r{#{Regexp.escape(child_record_hash)}})
              expect(page).to have_css(
                infinite_tree_current_node_selector(child_record),
                visible: :all
              )
            end
          end
        end
      end

      describe 'Modal controls' do
        before do
          visit edit_path
          wait_for_infinite_tree_inline_edit_form(form_prefix: 'resource')
        end

        describe 'Load via Spreadsheet' do
          it 'opens the bulk import modal when clicked' do
            click_button 'Load via Spreadsheet'

            aggregate_failures do
              expect(page).to have_css('#bulkIngestFileModal')
              expect(page).to have_css('#bulkFileButton')
              expect(page).to have_css('#excel_file', visible: :all)
            end
          end

          it 'links to help documentation for bulk imports' do
            doc_url = 'https://archivesspace.atlassian.net/wiki/spaces/ArchivesSpaceUserManual/pages/1173913646/Import+Archival+Objects+from+Excel+or+CSV+File+from+v2.8.1)'
            help_link = find('#infinite-tree-toolbar #load_via_spreadsheet_help_icon')
            expect(help_link[:href]).to eq(doc_url)
          end
        end

        describe 'Rapid Data Entry' do
          it 'opens the RDE modal when clicked' do
            click_button 'Rapid Data Entry'

            aggregate_failures do
              expect(page).to have_css('#rapidDataEntryModal')
              expect(page).to have_css('#rapidDataEntryModal .rde-wrapper')
              expect(page).to have_css('#rapidDataEntryModal #rde_form')
            end
          end
        end
      end

      describe 'Close Record' do
        before do
          visit "#{edit_path}#{ao_hash}"
          wait_for_ajax
        end

        it 'navigates to the readonly show view of the current record' do
          click_link 'Close Record'

          expect(page).to have_current_path(
            %r{#{Regexp.escape(show_path)}#{Regexp.escape(ao_hash)}},
            url: true
          )
          expect(page.current_url).not_to include('/edit')
          expect(page).not_to have_css('#infinite-tree-toolbar')
        end
      end
    end

    describe 'reorder mode' do
      before do
        visit edit_path
        wait_for_ajax

        enable_reorder_mode
      end

      describe 'toggling back to default mode' do
        before do
          disable_reorder_mode
        end

        let(:expected_title) { resource.title }

        it_behaves_like 'showing the Record Pane'
      end

      describe 'cut and paste controls' do
        describe 'Cut button' do
          context 'when the root node is the current record' do
            it 'is disabled when there are no multiselected nodes' do
              expect_infinite_tree_toolbar_cut_enabled(false)
            end

            it 'is enabled when there is a multiselected node' do
              meta_click_row(child_record.uri)
              expect_infinite_tree_toolbar_cut_enabled(true)
            end
          end

          context 'when a child node is the current record' do
            before { select_tree_row(child_record) }

            it 'is enabled' do
              expect_infinite_tree_toolbar_cut_enabled(true)
            end
          end

          context 'while a cut is already active' do
            before do
              select_tree_row(child_record)
              click_infinite_tree_toolbar_cut
            end

            it 'remains enabled so the user can start a new cut' do
              expect_infinite_tree_toolbar_cut_enabled(true)
            end
          end

          context 'when Cut is clicked again after a new multiselection' do
            before do
              select_tree_row(child_record)
              click_infinite_tree_toolbar_cut
              select_tree_row(ao2)
              meta_click_row(ao3.uri)
              click_infinite_tree_toolbar_cut
            end

            it 'clears the previous cut markers and marks the new cut' do
              aggregate_failures do
                expect(page).to have_no_css("li.node.cut[data-uri='#{child_record.uri}']")
                expect(page).to have_css("li.node.cut.multiselected[data-uri='#{ao2.uri}']")
                expect(page).to have_css("li.node.cut.multiselected[data-uri='#{ao3.uri}']")
              end
            end
          end
        end

        describe 'Paste button' do
          context 'before any cut' do
            it 'is disabled' do
              expect_infinite_tree_toolbar_paste_enabled(false)
            end
          end

          context 'after a cut' do
            before do
              select_tree_row(child_record)
              click_infinite_tree_toolbar_cut
            end

            context 'when the cut record is also the current record' do
              it 'stays disabled' do
                aggregate_failures do
                  expect(page).to have_css(".node.cut.current[data-uri='#{child_record.uri}']")
                  expect_infinite_tree_toolbar_paste_enabled(false)
                end
              end
            end

            context 'when the cut record is not the current record' do
              before do
                select_tree_row(ao3)
              end

              it 'is enabled' do
                expect(page).to have_css(".node.cut[data-uri='#{child_record.uri}']:not(.current)")
                expect(page).to have_css(".node.current[data-uri='#{ao3.uri}']")
                expect_infinite_tree_toolbar_paste_enabled(true)

                select_tree_row(root_record)
                expect(page).to have_css('.root.node.current')
                expect_infinite_tree_toolbar_paste_enabled(true)
              end

              context 'when reorder mode is toggled off and back on' do
                before do
                  disable_reorder_mode
                  enable_reorder_mode
                end

                it 'clears cut state and disables Paste' do
                  aggregate_failures do
                    expect(page).to have_css(".node.current[data-uri='#{ao3.uri}']")
                    expect(page).to have_no_css('.node.cut', visible: :all)
                    expect_infinite_tree_toolbar_cut_enabled(true)
                    expect_infinite_tree_toolbar_paste_enabled(false)
                  end
                end
              end
            end
          end
        end
      end

      describe 'Move menu controls' do
        let!(:single_child_resource) { create(:resource, title: "Single Child Resource #{now}") }
        let!(:single_child_resource_ao) do
          create(
            :archival_object,
            resource: { 'ref' => single_child_resource.uri },
            title: "Only AO #{now}"
          )
        end
        let!(:ao2_child_01) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao2.uri },
            title: "AO2 Child 01 #{now}"
          )
        end
        let!(:ao2_child_02) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao2.uri },
            title: "AO2 Child 02 #{now}"
          )
        end
        let!(:ao3_child_01) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao3.uri },
            title: "AO3 Child 01 #{now}"
          )
        end
        let!(:ao3_child_02) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao3.uri },
            title: "AO3 Child 02 #{now}"
          )
        end
        let!(:ao3_child_03) do
          create(
            :archival_object,
            resource: { 'ref' => resource.uri },
            parent: { 'ref' => ao3.uri },
            title: "AO3 Child 03 #{now}"
          )
        end
        let(:single_child_ao_edit_path) { "/resources/#{single_child_resource.id}/edit#tree::archival_object_#{single_child_resource_ao.id}" }

        def open_single_child_move_menu
          visit single_child_ao_edit_path
          wait_for_ajax
          enable_reorder_mode
          click_infinite_tree_toolbar_move_menu
        end

        before(:each) do
          visit edit_path
          wait_for_ajax
          enable_reorder_mode
        end

        it 'is disabled when the root node is the current record' do
          within '#infinite-tree-toolbar' do
            aggregate_failures do
              expect(page).to have_css('.js-itree-toolbar-move-toggle', visible: :visible)
              expect(page).to have_css('.js-itree-toolbar-move-toggle.disabled')
            end
          end
        end

        describe 'Move Up' do
          it 'is only enabled if the current record has a previous sibling' do
            select_tree_row(child_record)
            click_infinite_tree_toolbar_move_menu

            aggregate_failures do
              expect(move_menu_has_action?('up', enabled: false)).to be(true)
              select_tree_row(ao2)
              expect(move_menu_has_action?('up', enabled: true)).to be(true)
              select_tree_row(ao2_child_01)
              expect(move_menu_has_action?('up', enabled: false)).to be(true)
              select_tree_row(ao3)
              expect(move_menu_has_action?('up', enabled: true)).to be(true)
              select_tree_row(ao3_child_01)
              expect(move_menu_has_action?('up', enabled: false)).to be(true)
              select_tree_row(ao3_child_02)
              expect(move_menu_has_action?('up', enabled: true)).to be(true)
            end

            open_single_child_move_menu
            expect(move_menu_has_action?('up', enabled: false)).to be(true)
          end
        end

        describe 'Move Down' do
          it 'is only enabled if the current record has a next sibling' do
            select_tree_row(child_record)
            click_infinite_tree_toolbar_move_menu

            aggregate_failures do
              expect(move_menu_has_action?('down', enabled: true)).to be(true)
              select_tree_row(ao2)
              expect(move_menu_has_action?('down', enabled: true)).to be(true)
              select_tree_row(ao2_child_01)
              expect(move_menu_has_action?('down', enabled: true)).to be(true)
              select_tree_row(ao2_child_02)
              expect(move_menu_has_action?('down', enabled: false)).to be(true)
              select_tree_row(ao3)
              expect(move_menu_has_action?('down', enabled: false)).to be(true)
              select_tree_row(ao3_child_01)
              expect(move_menu_has_action?('down', enabled: true)).to be(true)
              select_tree_row(ao3_child_02)
              expect(move_menu_has_action?('down', enabled: true)).to be(true)
              select_tree_row(ao3_child_03)
              expect(move_menu_has_action?('down', enabled: false)).to be(true)
            end

            open_single_child_move_menu
            expect(move_menu_has_action?('down', enabled: false)).to be(true)
          end
        end

        describe 'Move Up a Level' do
          it 'is only enabled when the current record has a child-depth greater than 1' do
            select_tree_row(child_record)
            click_infinite_tree_toolbar_move_menu

            aggregate_failures do
              expect(move_menu_has_action?('up-level', enabled: false)).to be(true)
              select_tree_row(ao2)
              expect(move_menu_has_action?('up-level', enabled: false)).to be(true)
              select_tree_row(ao2_child_01)
              expect(move_menu_has_action?('up-level', enabled: true)).to be(true)
              select_tree_row(ao2_child_02)
              expect(move_menu_has_action?('up-level', enabled: true)).to be(true)
              select_tree_row(ao3)
              expect(move_menu_has_action?('up-level', enabled: false)).to be(true)
              select_tree_row(ao3_child_01)
              expect(move_menu_has_action?('up-level', enabled: true)).to be(true)
              select_tree_row(ao3_child_02)
              expect(move_menu_has_action?('up-level', enabled: true)).to be(true)
              select_tree_row(ao3_child_03)
              expect(move_menu_has_action?('up-level', enabled: true)).to be(true)
            end

            open_single_child_move_menu
            expect(move_menu_has_action?('up-level', enabled: false)).to be(true)
          end
        end

        describe 'Move Down Into' do
          let!(:ao4) do
            create(
              :archival_object,
              resource: { 'ref' => resource.uri },
              title: "AO4 #{now}"
            )
          end
          let!(:ao4_child_01) do
            create(
              :archival_object,
              resource: { 'ref' => resource.uri },
              parent: { 'ref' => ao4.uri },
              title: "AO4 Child 01 #{now}"
            )
          end

          before do
            visit edit_path
            wait_for_ajax
            enable_reorder_mode
          end

          it 'is only enabled when the current record has a sibling' do
            select_tree_row(child_record)
            click_infinite_tree_toolbar_move_menu

            aggregate_failures do
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao2)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao2_child_01)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao2_child_02)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao3)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao3_child_01)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao3_child_02)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao3_child_03)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao4)
              expect(move_menu_has_action?('down-into', enabled: true)).to be(true)
              select_tree_row(ao4_child_01)
              expect(move_menu_has_action?('down-into', enabled: false)).to be(true)
            end

            open_single_child_move_menu
            expect(move_menu_has_action?('down-into', enabled: false)).to be(true)
          end

          it 'limits the submenu to 20 balanced siblings' do
            Array.new(24) do |index|
              create(
                :archival_object,
                resource: { 'ref' => resource.uri },
                title: "Extra Sibling #{index} #{now}"
              )
            end

            visit edit_path
            wait_for_ajax
            enable_reorder_mode

            all_uris = root_child_uris
            current_uri = all_uris[12]
            current_id = "archival_object_#{current_uri.split('/').last}"

            select_tree_row(current_uri)
            click_infinite_tree_toolbar_move_menu

            target_uris = down_into_submenu_target_uris
            current_index = all_uris.index(current_uri)
            expected_target_uris =
              all_uris[(current_index - 10)...current_index] +
              all_uris[(current_index + 1)..(current_index + 10)]

            aggregate_failures do
              expect(current_index).to be >= 10
              expect(current_index).to be <= (all_uris.length - 11)
              expect(current_id).to start_with('archival_object_')
              expect(target_uris.length).to eq(20)
              expect(target_uris).to eq(expected_target_uris)
            end
          end
        end
      end
    end

    context 'while the record pane is dirty' do
      before do
        visit edit_path
        wait_for_ajax
        select_tree_row(ao)
      end

      it 'disables mutating controls' do
        within '#infinite-tree-record-pane' do
          fill_in 'archival_object_title_', with: 'Modified Title'
        end

        %w[
          .js-itree-toolbar-add-child
          .js-itree-toolbar-add-sibling
          .js-itree-toolbar-add-duplicate
          .js-itree-toolbar-load-bulk
          .js-itree-toolbar-rde
          .js-itree-toolbar-finish-editing
        ].each do |selector|
          expect(page).to have_css("#{selector}.disabled")
        end
      end
    end
  end
end
