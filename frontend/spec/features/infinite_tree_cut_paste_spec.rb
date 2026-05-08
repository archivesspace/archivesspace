# frozen_string_literal: true

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

  def execute_js(script)
    page.execute_script(script)
  end

  def evaluate_js(script)
    page.evaluate_script(script)
  end

  def enable_reorder_mode
    find('.js-itree-toolbar-reorder-toggle').click
  end

  def click_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) throw new Error('no row for #{uri}');
        var row = li.querySelector('.node-row');
        row.dispatchEvent(new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        }));
      })();
    JS
  end

  def mousedown_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) throw new Error('no row for #{uri}');
        var row = li.querySelector('.node-row');
        row.dispatchEvent(new MouseEvent('mousedown', {
          bubbles: true,
          cancelable: true,
          view: window,
          button: 0,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        }));
      })();
    JS
  end

  def expand_node(uri)
    execute_js(<<~JS)
      (function() {
        var li = document.querySelector("#infinite-tree-container li.node[data-uri='#{uri}']");
        if (!li) return;
        var btn = li.querySelector(':scope > .node-row .node-expand');
        if (btn) btn.click();
      })();
    JS
  end

  def install_accept_children_capture
    execute_js(<<~JS)
      window.__itreeAcceptChildrenRequests = [];
      window.__itreeReorderEvents = [];
      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/accept_children') !== -1) {
          window.__itreeAcceptChildrenRequests.push({
            url: url,
            body: init && init.body ? init.body.toString() : ''
          });
        }
        return originalFetch(input, init);
      };

      [
        'infiniteTreeReorder:moveStart',
        'infiniteTreeReorder:moveSuccess',
        'infiniteTreeReorder:moveError',
        'infiniteTreeReorder:moveSkipped'
      ].forEach(function(name) {
        document.addEventListener(name, function(event) {
          window.__itreeReorderEvents.push({
            name: event.type,
            detail: event.detail || {}
          });
        });
      });
    JS
  end

  def accept_children_requests
    evaluate_js('window.__itreeAcceptChildrenRequests')
  end

  before do
    visit edit_path
    wait_for_ajax
  end

  it 'disables Cut when no eligible nodes exist and enables Cut when a non-root row is selected' do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax

    enable_reorder_mode
    expect(page).to have_css('.js-itree-toolbar-cut.disabled')

    within '#infinite-tree-container' do
      click_link ao.title
    end
    expect(page).to have_no_css('.js-itree-toolbar-cut.disabled')
  end

  it 'keeps Paste disabled until a cut exists and a non-cut .selected destination exists' do
    enable_reorder_mode

    # Paste starts disabled with no cut
    aggregate_failures do
      expect(page).to have_css('.js-itree-toolbar-paste.disabled')
      expect(page).to have_css('.js-itree-toolbar-cut')
    end

    # Select two rows as cut sources (ao via click_link, ao2 via Cmd+click)
    within '#infinite-tree-container' do
      click_link ao.title
    end
    click_row(ao2.uri, meta: true)
    find('.js-itree-toolbar-cut').click

    # After multi-row cut, ao remains .selected but is .cut → Paste stays disabled
    expect(page).to have_css('.js-itree-toolbar-paste.disabled')

    # Clicking ao3 updates .selected to a non-cut row → Paste enables
    within '#infinite-tree-container' do
      click_link ao3.title
    end
    expect(page).to have_no_css('.js-itree-toolbar-paste.disabled')

    # Toggling reorder off and back on resets cut state → Paste disabled again
    find('.js-itree-toolbar-reorder-toggle').click
    find('.js-itree-toolbar-reorder-toggle').click

    expect(page).to have_css('.js-itree-toolbar-paste.disabled')
  end

  it 'cuts multiselection and pastes using deduped effective move set' do
    install_accept_children_capture
    enable_reorder_mode
    expand_node(ao2.uri)
    wait_for_ajax

    # Parent/child explicit multiselection is intentionally blocked in reorder mode
    # by InfiniteTreeSelection ancestry-lock rules. Seed that explicit selection
    # directly so this spec still exercises cut/paste effective-set deduping.
    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var parent = document.querySelector("li.node[data-uri='#{ao2.uri}']");
        var child = document.querySelector("li.node[data-uri='#{child_ao.uri}']");
        if (!container || !parent || !child) throw new Error('required nodes missing');

        parent.classList.add('multiselected');
        child.classList.add('multiselected');

        container.dispatchEvent(new CustomEvent('infiniteTreeSelection:changed', {
          bubbles: true,
          detail: {
            selectedNodes: [parent, child],
            anchorNode: child
          }
        }));
      })();
    JS
    find('.js-itree-toolbar-cut').click

    aggregate_failures do
      expect(page).to have_css('li.node.cut')
    end

    # Select a cut row → Paste stays disabled
    within '#infinite-tree-container' do
      click_link ao2.title
    end
    expect(page).to have_css('.js-itree-toolbar-paste.disabled')

    # Select a non-cut row → Paste enables
    within '#infinite-tree-container' do
      click_link ao3.title
    end
    expect(page).to have_no_css('.js-itree-toolbar-paste.disabled')

    find('.js-itree-toolbar-paste').click
    wait_for_ajax

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

  it 'targets .selected destination, not .multiselected, when they differ' do
    install_accept_children_capture

    within '#infinite-tree-container' do
      click_link ao.title
    end
    wait_for_ajax

    enable_reorder_mode
    mousedown_row(ao3.uri)
    find('.js-itree-toolbar-cut').click

    # ao remains .selected; ao3 is .multiselected.cut only → Paste targets ao
    find('.js-itree-toolbar-paste').click
    wait_for_ajax

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include("/archival_objects/#{ao.id}/accept_children")
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao3.uri)}")
    end
  end

  it 'enables Paste when root is .selected after cut' do
    visit "#{edit_path}#{ao_hash}"
    wait_for_ajax

    enable_reorder_mode
    find('.js-itree-toolbar-cut').click

    expect(page).to have_css('.js-itree-toolbar-paste.disabled')

    within '#infinite-tree-container' do
      click_link resource.title
    end
    wait_for_ajax

    aggregate_failures do
      expect(page).to have_css('li.node.cut')
      expect(page).to have_css('#infinite-tree-container li.node.root.selected')
      expect(page).to have_no_css('#infinite-tree-container li.node.multiselected')
      expect(page).to have_no_css('.js-itree-toolbar-paste.disabled')
    end
  end

  it 'pastes cut rows as children of the root when root is the paste target' do
    install_accept_children_capture
    visit "#{edit_path}#{ao_hash}"
    wait_for_ajax

    enable_reorder_mode
    find('.js-itree-toolbar-cut').click

    within '#infinite-tree-container' do
      click_link resource.title
    end
    wait_for_ajax

    find('.js-itree-toolbar-paste').click
    wait_for_ajax

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include("/resources/#{resource.id}/accept_children")
      expect(request['body']).to include("children%5B%5D=#{ERB::Util.url_encode(ao.uri)}")
      expect(page).to have_no_css('li.node.cut')
    end
  end

  it 'enables Paste to .selected when cut rows are only .multiselected' do
    within '#infinite-tree-container' do
      click_link ao.title
    end
    wait_for_ajax

    enable_reorder_mode
    mousedown_row(ao3.uri)
    find('.js-itree-toolbar-cut').click

    aggregate_failures do
      expect(page).to have_css("li.node.cut.multiselected[data-uri='#{ao3.uri}']")
      expect(page).to have_css("#infinite-tree-container li.node.selected[data-uri='#{ao.uri}']")
      expect(page).to have_no_css('.js-itree-toolbar-paste.disabled')
    end
  end

  it 'does not paste when target is part of the cut set' do
    install_accept_children_capture
    enable_reorder_mode

    within '#infinite-tree-container' do
      click_link ao.title
    end

    find('.js-itree-toolbar-cut').click

    expect(page).to have_css('.js-itree-toolbar-paste.disabled')

    find('.js-itree-toolbar-paste').click
    wait_for_ajax

    expect(accept_children_requests).to eq([])
    expect(page).to have_css("li.node.cut[data-uri='#{ao.uri}']")
  end
end
