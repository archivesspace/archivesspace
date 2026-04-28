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

    describe 'Shift + click extends selection across all depths' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        # Guard the precondition: the level-2 child_ao is now in the DOM
        # between the two level-1 siblings ao2 and ao3, so cross-depth range
        # behavior is actually being exercised.
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'extends across same-level siblings and includes deeper rows in the range' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, ao2.uri, child_ao.uri, ao3.uri])
      end

      it 'extends from a level-1 anchor to a level-2 endpoint inside an expanded parent' do
        click_row(ao.uri, meta: true)
        click_row(child_ao.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao.uri, ao2.uri, child_ao.uri])

        evt = last_changed_event
        expect(evt['detail']['selectedUris']).to eq([ao.uri, ao2.uri, child_ao.uri])
        expect(evt['detail']['anchorUri']).to eq(child_ao.uri)
      end

      it 'extends from a level-2 anchor to a level-1 endpoint, walking backward across depths' do
        click_row(child_ao.uri, meta: true)
        click_row(ao.uri, shift: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([child_ao.uri, ao.uri, ao2.uri])
      end
    end

    describe 'ancestor/descendant overlap is allowed in the explicit selection' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
        expect(page).to have_css("li.node[data-uri='#{child_ao.uri}']")
      end

      it 'lets Cmd/Ctrl + click add a descendant after its ancestor is already selected' do
        click_row(ao2.uri, meta: true)
        click_row(child_ao.uri, meta: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([ao2.uri, child_ao.uri])
      end

      it 'lets Cmd/Ctrl + click add an ancestor after its descendant is already selected' do
        click_row(child_ao.uri, meta: true)
        click_row(ao2.uri, meta: true)

        uris = data_selection_uris.split(',')
        expect(uris).to eq([child_ao.uri, ao2.uri])
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

    describe 'expand and collapse do not mutate the selection' do
      before do
        expand_node(ao2.uri)
        wait_for_ajax
      end

      it 'preserves selected descendants in the explicit selection when their ancestor collapses' do
        click_row(child_ao.uri, meta: true)
        expect(data_selection_uris).to eq(child_ao.uri)

        collapse_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq(child_ao.uri)
      end

      it 'preserves a multi-row selection across collapse + re-expand' do
        click_row(ao.uri, meta: true)
        click_row(child_ao.uri, meta: true)
        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        collapse_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")

        expand_node(ao2.uri)
        wait_for_ajax

        expect(data_selection_uris).to eq("#{ao.uri},#{child_ao.uri}")
        expect(page).to have_css(
          "li.node[data-uri='#{child_ao.uri}'].multiselected"
        )
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

    describe 'selection-order badges' do
      def badge_text(uri)
        evaluate_js(<<~JS)
          (function() {
            var li = document.querySelector(
              '#infinite-tree-container li.node[data-uri="#{uri}"]'
            );
            if (!li) return null;
            var badge = li.querySelector(
              ':scope > .node-row > .node-body > [data-column="drag-handle"] > .selection-order-badge'
            );
            return badge ? badge.textContent : null;
          })();
        JS
      end

      it 'leaves every badge empty when exactly one row is selected' do
        click_row(ao.uri, meta: true)

        expect(badge_text(ao.uri)).to eq('')
      end

      it 'numbers selected rows in selection order when multiple rows are selected' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(badge_text(ao.uri)).to eq('1')
        expect(badge_text(ao3.uri)).to eq('2')
      end

      it 'appends subsequent selections and renumbers when a middle row is removed' do
        click_row(ao.uri, meta: true)
        click_row(ao2.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(badge_text(ao.uri)).to eq('1')
        expect(badge_text(ao2.uri)).to eq('2')
        expect(badge_text(ao3.uri)).to eq('3')

        click_row(ao2.uri, meta: true)

        expect(badge_text(ao.uri)).to eq('1')
        expect(badge_text(ao2.uri)).to eq('')
        expect(badge_text(ao3.uri)).to eq('2')
      end

      it 'clears all badge text and data-selection-uris when reorder mode turns off' do
        click_row(ao.uri, meta: true)
        click_row(ao3.uri, meta: true)

        expect(badge_text(ao.uri)).to eq('1')
        expect(badge_text(ao3.uri)).to eq('2')

        find('.js-itree-toolbar-reorder-toggle').click

        expect(badge_text(ao.uri)).to eq('')
        expect(badge_text(ao3.uri)).to eq('')
        expect(data_selection_uris).to be_nil
      end
    end
  end

  context 'drag-handle column visibility and widths' do
    def column_rect_width(uri, column_name)
      evaluate_js(<<~JS)
        (function() {
          var li = document.querySelector(
            '#infinite-tree-container li.node[data-uri="#{uri}"]'
          );
          if (!li) return null;
          var col = li.querySelector(
            ':scope > .node-row > .node-body > [data-column="#{column_name}"]'
          );
          if (!col) return null;
          return col.getBoundingClientRect().width;
        })();
      JS
    end

    def handle_display(uri)
      evaluate_js(<<~JS)
        (function() {
          var li = document.querySelector(
            '#infinite-tree-container li.node[data-uri="#{uri}"]'
          );
          var col = li.querySelector(
            ':scope > .node-row > .node-body > [data-column="drag-handle"]'
          );
          return window.getComputedStyle(col).display;
        })();
      JS
    end

    it 'hides the drag-handle column by default and reveals it in reorder mode' do
      expect(handle_display(ao.uri)).to eq('none')

      enable_reorder_mode

      expect(page).to have_css('#infinite-tree-container.reorder-mode')
      expect(handle_display(ao.uri)).not_to eq('none')
    end

    it 'leaves non-title column pixel widths unchanged across reorder toggle' do
      level_before = column_rect_width(ao.uri, 'level')
      type_before = column_rect_width(ao.uri, 'type')
      container_before = column_rect_width(ao.uri, 'container')

      enable_reorder_mode
      expect(page).to have_css('#infinite-tree-container.reorder-mode')

      level_after = column_rect_width(ao.uri, 'level')
      type_after = column_rect_width(ao.uri, 'type')
      container_after = column_rect_width(ao.uri, 'container')

      expect(level_after).to be_within(0.5).of(level_before)
      expect(type_after).to be_within(0.5).of(type_before)
      expect(container_after).to be_within(0.5).of(container_before)
    end

    it 'shrinks the title column by the handle column width when reorder turns on' do
      title_before = column_rect_width(ao.uri, 'title')

      enable_reorder_mode
      expect(page).to have_css('#infinite-tree-container.reorder-mode')

      title_after = column_rect_width(ao.uri, 'title')
      handle_width = column_rect_width(ao.uri, 'drag-handle')

      expect(handle_width).to be > 0
      expect(title_before - title_after).to be_within(0.5).of(handle_width)
    end
  end
end
