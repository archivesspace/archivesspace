# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Infinite Tree Selection (reorder-mode multi-select)', js: true do
  include_context 'infinite tree integration setup'

  let(:edit_path) { "/resources/#{resource.id}/edit" }
  let(:root_hash) { "#tree::resource_#{resource.id}" }

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

  def install_selection_event_capture
    execute_js(<<~JS)
      window.__itreeSelectionEvents = [];
      const names = [
        'infiniteTreeSelection:changed',
        'infiniteTreeSelection:cleared'
      ];
      names.forEach(function(name) {
        document.addEventListener(name, function(event) {
          const detail = {};
          if (event.detail && event.detail.selectedNodes) {
            detail.selectedUris = event.detail.selectedNodes.map(function(n) {
              return n.getAttribute('data-uri');
            });
          }
          if (event.detail && event.detail.anchorNode) {
            detail.anchorUri = event.detail.anchorNode.getAttribute('data-uri');
          }
          window.__itreeSelectionEvents.push({ name: event.type, detail: detail });
        });
      });
    JS
  end

  def selection_events
    evaluate_js('window.__itreeSelectionEvents')
  end

  def last_changed_event
    evaluate_js(<<~JS)
      (function() {
        var evs = window.__itreeSelectionEvents.filter(function(e) {
          return e.name === 'infiniteTreeSelection:changed';
        });
        return evs[evs.length - 1] || null;
      })();
    JS
  end

  def cleared_event_count
    evaluate_js(<<~JS)
      window.__itreeSelectionEvents.filter(function(e) {
        return e.name === 'infiniteTreeSelection:cleared';
      }).length
    JS
  end

  def data_selection_uris
    evaluate_js(
      "document.querySelector('#infinite-tree-container').dataset.selectionUris || null"
    )
  end

  # Dispatch a synthetic click on an li.node's .node-row with the given modifiers.
  # Capture-phase listener in InfiniteTreeSelection will intercept before
  # InfiniteTree's bubble-phase title click handler routes.
  def click_row(uri, modifiers = {})
    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var li = container.querySelector('li.node[data-uri="#{uri}"]');
        if (!li) throw new Error('No li with data-uri=#{uri}');
        var row = li.querySelector('.node-row');
        if (!row) throw new Error('No .node-row for #{uri}');
        var ev = new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
          metaKey: #{!!modifiers[:meta]},
          ctrlKey: #{!!modifiers[:ctrl]},
          shiftKey: #{!!modifiers[:shift]}
        });
        row.dispatchEvent(ev);
      })();
    JS
  end

  def expand_node(uri)
    execute_js(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var li = container.querySelector('li.node[data-uri="#{uri}"]');
        if (!li) return;
        var btn = li.querySelector(':scope > .node-row .node-expand');
        if (btn) btn.click();
      })();
    JS
  end

  def collapse_node(uri)
    expand_node(uri)
  end

  def enable_reorder_mode
    find('.js-itree-toolbar-reorder-toggle').click
  end

  before do
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
    install_selection_event_capture
  end

  context 'when reorder mode is off' do
    it 'plain clicks retain router navigation behavior' do
      within '#infinite-tree-container' do
        click_link ao.title
      end
      wait_for_ajax

      expect(page.current_url).to include("tree::archival_object_#{ao.id}")
      expect(data_selection_uris).to be_nil
    end

    it 'ignores modifier-keyed clicks (no selection mutation)' do
      click_row(ao.uri, meta: true)

      expect(selection_events).to eq([])
      expect(data_selection_uris).to be_nil
      expect(page).to have_no_css('#infinite-tree-container .node.multiselected')
    end
  end

  context 'when reorder mode is on' do
    before { enable_reorder_mode }

    it 'toggles .reorder-mode on the tree container' do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
    end

    describe 'Cmd/Ctrl + click toggles membership' do
      it 'adds rows with meta key, toggles off on second meta click' do
        click_row(ao.uri, meta: true)

        expect(page).to have_css("li.node[data-uri='#{ao.uri}'].multiselected")
        expect(data_selection_uris).to eq(ao.uri)

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri])
        expect(evt['detail']['anchorUri']).to eq(ao.uri)

        click_row(ao.uri, meta: true)

        expect(page).to have_no_css('.node.multiselected')
        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end

      it 'adds rows with ctrl key and preserves order in data-selection-uris' do
        click_row(ao.uri, ctrl: true)
        click_row(ao3.uri, ctrl: true)

        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri, ao3.uri])
        expect(evt['detail']['anchorUri']).to eq(ao3.uri)
      end
    end

    describe 'Shift + click extends selection at same level only' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        # Guard the precondition: the level-2 child_ao is now in the DOM between
        # the two level-1 siblings ao2 and ao3, so the same-level filter is
        # actually being exercised.
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'adds same-level siblings and skips the deeper child' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to include(ao.uri, ao2.uri, ao3.uri)
        expect(uris).not_to include(child_ao.uri)
      end
    end

    describe 'plain click' do
      it 'replaces selection with just the clicked row and does not navigate' do
        click_row(ao.uri, ctrl: true)
        click_row(ao3.uri, ctrl: true)
        expect(data_selection_uris).to eq("#{ao.uri},#{ao3.uri}")

        url_before = page.current_url
        click_row(ao2.uri)

        expect(data_selection_uris).to eq(ao2.uri)
        expect(page.current_url).to eq(url_before)
      end
    end

    describe 'outside click' do
      it 'clears selection when mousedown lands outside tree/toolbar/resizer' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        execute_js(<<~JS)
          document.body.dispatchEvent(
            new MouseEvent('mousedown', { bubbles: true, cancelable: true })
          );
        JS

        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end

      it 'preserves selection when mousedown is inside the toolbar' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        execute_js(<<~JS)
          document.querySelector('#infinite-tree-toolbar')
            .dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
        JS

        expect(data_selection_uris).to eq(ao.uri)
      end
    end

    describe 'ancestor/descendant lockout' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'marks descendants with .selection-locked and rejects their selection' do
        click_row(ao2.uri, meta: true)

        expect(page).to have_css(
          "li.node[data-uri='#{child_ao.uri}'].selection-locked"
        )

        click_row(child_ao.uri, meta: true)

        expect(data_selection_uris).to eq(ao2.uri)
      end

      it 'marks ancestors with .selection-locked when a descendant is selected' do
        click_row(child_ao.uri, meta: true)

        expect(page).to have_css(
          "li.node[data-uri='#{ao2.uri}'].selection-locked"
        )

        click_row(ao2.uri, meta: true)

        expect(data_selection_uris).to eq(child_ao.uri)
      end
    end

    describe 'collapse prune' do
      # This is parity with the largetree but is questionable behavior in my opinion.
      before do
        expand_node(ao2.uri)
        wait_for_ajax
      end

      it 'drops selected rows that become hidden after an ancestor collapses' do
        click_row(child_ao.uri, meta: true)
        expect(data_selection_uris).to eq(child_ao.uri)

        collapse_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to be_nil
      end
    end

    describe 'toggling reorder mode off' do
      it 'clears selection and removes .reorder-mode from the container' do
        click_row(ao.uri, meta: true)
        expect(data_selection_uris).to eq(ao.uri)

        find('.js-itree-toolbar-reorder-toggle').click

        expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
        expect(data_selection_uris).to be_nil
        expect(cleared_event_count).to be >= 1
      end
    end
  end
end
