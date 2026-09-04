# frozen_string_literal: true

# Cut/Paste button enable/disable rules live in infinite_tree_toolbar_spec.rb
# under reorder mode > Cut and paste controls. This file covers paste execution,
# accept_children API verification, and effective move-set deduping.

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Cut/Paste', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }
  let(:ao_hash) { "#tree::archival_object_#{ao.id}" }

  let!(:ao2) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Sibling AO #{now}"
    )
  end

  let!(:child_ao) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      parent: { 'ref' => ao2.uri },
      title: "Child AO #{now}"
    )
  end

  let!(:ao3) do
    create(
      :archival_object,
      resource: { 'ref' => resource.uri },
      title: "Third AO #{now}"
    )
  end

  before do
    visit edit_path
    wait_for_ajax
  end

  it 'cuts multiselection and pastes using deduped effective move set' do
    install_accept_children_capture
    enable_reorder_mode
    expand_tree_node(ao2.uri)
    wait_for_ajax

    # Parent/child explicit multiselection is intentionally blocked in reorder mode
    # by InfiniteTreeMultiSelection ancestry-lock rules. Seed that explicit selection
    # directly via JS (documented exception) so this spec still exercises cut/paste
    # effective-set deduping.
    page.execute_script(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var parent = document.querySelector("li.node[data-uri='#{ao2.uri}']");
        var child = document.querySelector("li.node[data-uri='#{child_ao.uri}']");
        if (!container || !parent || !child) throw new Error('required nodes missing');

        parent.classList.add('multiselected');
        child.classList.add('multiselected');

        container.dispatchEvent(new CustomEvent('infiniteTreeMultiSelection:changed', {
          bubbles: true,
          detail: {
            selectedNodes: [parent, child],
            anchorNode: child
          }
        }));
      })();
    JS
    click_infinite_tree_toolbar_cut

    aggregate_failures do
      expect(page).to have_css('li.node.cut')
    end

    select_tree_row(ao3)
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include("/archival_objects/#{ao3.id}/accept_children")
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao2.uri)}")
      expect(request['body']).not_to include("children%5B%5D=#{ERB::Util.url_encode(child_ao.uri)}")
      expect(request['body']).to include('index=0')
      expect(page).to have_no_css('li.node.cut')
    end
  end

  it 'targets .current destination, not .multiselected, when they differ' do
    install_accept_children_capture

    select_tree_row(ao)
    enable_reorder_mode
    click_tree_row(ao3.uri)
    click_infinite_tree_toolbar_cut

    # ao remains .current; ao3 is .multiselected.cut only → Paste targets ao
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include("/archival_objects/#{ao.id}/accept_children")
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao3.uri)}")
    end
  end

  it 'pastes cut rows as children of the root when root is the paste target' do
    install_accept_children_capture
    visit "#{edit_path}#{ao_hash}"
    wait_for_ajax

    enable_reorder_mode
    click_infinite_tree_toolbar_cut

    select_tree_row(root_record)
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include("/resources/#{resource.id}/accept_children")
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao.uri)}")
      expect(page).to have_no_css('li.node.cut')
    end
  end

  it 'does not paste when target is part of the cut set' do
    install_accept_children_capture
    enable_reorder_mode

    select_tree_row(ao)
    click_infinite_tree_toolbar_cut

    find('.js-itree-toolbar-paste').click
    wait_for_ajax

    aggregate_failures do
      expect(accept_children_requests).to eq([])
      expect(page).to have_css("li.node.cut[data-uri='#{ao.uri}']")
    end
  end
end
