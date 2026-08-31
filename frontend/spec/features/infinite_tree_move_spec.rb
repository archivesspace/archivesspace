# frozen_string_literal: true

# Move menu action enable/disable rules live in infinite_tree_toolbar_spec.rb
# under reorder mode > Move menu controls. This file covers move execution,
# accept_children API verification, and reorder in-flight behavior.

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Move', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:nested_hash) { nested_child_record_hash }

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
  let!(:nested_child_record) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      parent: { 'ref' => child_record.uri },
      title: "Nested AO #{now}"
    )
  end

  def expected_sibling_order_after_move(before_order, uri, offset)
    order = before_order.dup
    index = order.index(uri)
    order.delete(uri)
    order.insert(index + offset, uri)
    order
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
  end

  context 'when reorder mode is off' do
    it 'hides the Move toggle' do
      select_tree_row(ao)

      within '#infinite-tree-toolbar' do
        expect(page).to have_no_css('.js-itree-toolbar-move-toggle', visible: :visible)
      end
    end
  end

  context 'when reorder mode is on' do
    before { enable_reorder_mode }

    describe 'Up' do
      it 'moves a node up among siblings' do
        before_order = root_child_uris

        open_move_menu_for_node(ao2)
        click_move_menu_action('up')
        wait_for_reorder_idle

        aggregate_failures do
          expect(root_child_uris).to eq(expected_sibling_order_after_move(before_order, ao2.uri, -1))
          expect(selected_uri).to eq(ao2.uri)
        end
      end

      it 'refreshes menu options after a move' do
        open_move_menu_for_node(ao2)
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

      context 'for the first sibling' do
        let(:first_uri) { root_child_uris.first }

        it 'does not send accept_children when up is disabled' do
          install_accept_children_capture

          open_move_menu_for_node(first_uri)

          expect(move_menu_has_action?('up', enabled: false)).to be(true)
          expect(accept_children_requests).to eq([])
        end
      end
    end

    describe 'Down' do
      it 'moves a node down among siblings' do
        before_order = root_child_uris

        open_move_menu_for_node(ao)
        click_move_menu_action('down')
        wait_for_reorder_idle

        aggregate_failures do
          expect(root_child_uris).to eq(expected_sibling_order_after_move(before_order, ao.uri, 1))
          expect(selected_uri).to eq(ao.uri)
        end
      end
    end

    describe 'Up a level' do
      before do
        visit "#{edit_path}#{nested_hash}"
        wait_for_ajax
      end

      it 'moves a nested node up a level' do
        before_order = root_child_uris

        open_move_menu_for_node(nested_child_record)
        click_move_menu_action('up-level')
        wait_for_reorder_idle

        aggregate_failures do
          expect(child_uris_for(ao.uri)).not_to include(nested_child_record.uri)
          expect(root_child_uris).to eq(before_order + [nested_child_record.uri])
          expect(selected_uri).to eq(nested_child_record.uri)
        end
      end
    end

    describe 'Down into' do
      it 'moves a node down into a sibling as last child' do
        open_move_menu_for_node(ao)
        click_move_menu_action('down-into', target_node_id: "archival_object_#{ao2.id}")
        wait_for_reorder_idle

        aggregate_failures do
          expect(root_child_uris).not_to include(ao.uri)
          expect(child_uris_for(ao2.uri).last).to eq(ao.uri)
          expect(selected_uri).to eq(ao.uri)
        end
      end
    end

    context 'when multiselection is present' do
      it 'moves only the selected row' do
        install_accept_children_capture
        before_order = root_child_uris

        select_tree_row(ao2)
        meta_click_row(ao.uri)
        meta_click_row(ao3.uri)

        aggregate_failures do
          expect(page).to have_css("li.node[data-uri='#{ao2.uri}'].selected")
          expect(page).to have_css("li.node[data-uri='#{ao.uri}'].multiselected")
          expect(page).to have_css("li.node[data-uri='#{ao3.uri}'].multiselected")
        end

        click_infinite_tree_toolbar_move_menu
        click_move_menu_action('up')
        wait_for_reorder_idle

        request = accept_children_requests.last
        expect(request).not_to be_nil

        aggregate_failures do
          expect(root_child_uris).to eq(expected_sibling_order_after_move(before_order, ao2.uri, -1))
          expect(selected_uri).to eq(ao2.uri)
          expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao2.uri)}")
          expect(request['body']).not_to include("children%5B%5D=#{ERB::Util.url_encode(ao.uri)}")
          expect(request['body']).not_to include("children%5B%5D=#{ERB::Util.url_encode(ao3.uri)}")
        end
      end
    end

    context 'while a reorder move is in flight' do
      it 'ignores a second move' do
        install_accept_children_capture
        before_order = root_child_uris

        open_move_menu_for_node(ao2)

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
          expect(request['body']).to include(ERB::Util.url_encode(ao2.uri))
        end
      end
    end
  end
end
