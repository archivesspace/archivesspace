# frozen_string_literal: true

# Move menu action enable/disable rules live in infinite_tree_toolbar_spec.rb
# under reorder mode > Move menu controls. This file covers move execution,
# accept_children API verification, and reorder in-flight behavior.

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Move', js: true do
  context 'Resources' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:resources)

    it_behaves_like 'toggling reorder mode'
    it_behaves_like 'moving records in reorder mode'

    context 'when reorder mode is on' do
      before { enable_reorder_mode }

      it 'moves a row up among siblings' do
        before_order = root_child_uris

        open_move_menu_for_node(sibling2)
        click_move_menu_action('up')
        wait_for_reorder_idle

        aggregate_failures do
          expect(root_child_uris).to eq(expected_sibling_order_after_move(before_order, sibling2.uri, -1))
          expect(current_uri).to eq(sibling2.uri)
        end
      end

      it 'refreshes menu options after a move' do
        open_move_menu_for_node(sibling2)
        within '.js-itree-toolbar-move-menu' do
          expect(page).to have_css('button[data-move-action="up"]:not([disabled])')
        end

        click_move_menu_action('up')
        wait_for_reorder_idle

        click_infinite_tree_toolbar_move_menu
        within '.js-itree-toolbar-move-menu' do
          expect(page).to have_css('button[data-move-action="down"]:not([disabled])')
          expect(page).to have_css('button[data-move-action="up"][disabled]')
        end
      end

      context 'while a reorder move is in flight' do
        it 'ignores a second move' do
          install_accept_children_capture
          before_order = root_child_uris

          open_move_menu_for_node(sibling2)

          # Rapid double-click the up action before the DOM can refresh between clicks
          within '.js-itree-toolbar-move-menu' do
            button = find("button[data-move-action='up']:not([data-target-node-id])", match: :first)
            page.execute_script('arguments[0].click(); arguments[0].click();', button.native)
          end

          wait_for_reorder_idle

          after_order = root_child_uris

          aggregate_failures do
            expect(accept_children_request_count).to eq(1)
            expect(after_order).not_to eq(before_order)
            request = last_accept_children_request
            expect(request['body']).to include(ERB::Util.url_encode(sibling2.uri))
          end
        end
      end
    end
  end

  context 'Digital Objects' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:digital_objects)

    it_behaves_like 'toggling reorder mode'
    it_behaves_like 'moving records in reorder mode'
  end

  context 'Classifications' do
    include_context 'infinite tree reorder hierarchy setup', InfiniteTreeHierarchyConfigs::REORDER.fetch(:classifications)

    it_behaves_like 'toggling reorder mode'
    it_behaves_like 'moving records in reorder mode'
  end
end
