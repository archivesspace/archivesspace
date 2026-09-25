# frozen_string_literal: true

# Shared setup and cross-hierarchy reorder parity examples for Infinite Tree.
# Deep tree-engine edge cases (multiselection ancestry, drag previews, etc.) stay
# in the feature specs under Resources as representative coverage.
RSpec.shared_context 'infinite tree reorder hierarchy setup' do |config|
  include_context 'infinite tree integration hierarchy setup', config.merge(run_indexer: true)

  let(:sibling2) do
    create(
      config[:child_factory],
      title: "Sibling 2 #{now}",
      config[:root_relationship_key] => { ref: root_record.uri }
    )
  end

  let(:sibling3) do
    create(
      config[:child_factory],
      title: "Sibling 3 #{now}",
      config[:root_relationship_key] => { ref: root_record.uri }
    )
  end

  let(:nested_under_sibling2) do
    create(
      config[:child_factory],
      title: "Nested under sibling 2 #{now}",
      config[:root_relationship_key] => { ref: root_record.uri },
      parent: { ref: sibling2.uri }
    )
  end

  def expected_sibling_order_after_move(before_order, uri, offset)
    order = before_order.dup
    index = order.index(uri)
    order.delete(uri)
    order.insert(index + offset, uri)
    order
  end

  def frontend_accept_children_path_for(record)
    uri = record.respond_to?(:uri) ? record.uri : record.to_s
    parts = uri.split('/')
    "/#{parts[-2]}/#{parts[-1]}/accept_children"
  end

  before do
    sibling2
    sibling3
    nested_child_record
    nested_under_sibling2
    run_indexer
    visit "#{edit_path}#{root_hash}"
    wait_for_ajax
  end
end

RSpec.shared_examples 'toggling reorder mode' do
  it 'enters and exits reorder mode on the tree container' do
    expect(page).to have_no_css('#infinite-tree-container.reorder-mode')

    enable_reorder_mode
    wait_for_reorder_mode_ready

    expect(page).to have_css('#infinite-tree-container.reorder-mode')

    disable_reorder_mode

    expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
  end
end

RSpec.shared_examples 'moving records in reorder mode' do
  context 'when reorder mode is on' do
    before { enable_reorder_mode }

    it 'disables the Move menu when the root is current' do
      expect_infinite_tree_toolbar_move_enabled(false)
    end

    it 'moves a root-level child down among siblings' do
      before_order = root_child_uris

      open_move_menu_for_node(child_record)
      click_move_menu_action('down')
      wait_for_reorder_idle

      aggregate_failures do
        expect(root_child_uris).to eq(
          expected_sibling_order_after_move(before_order, child_record.uri, 1)
        )
        expect(current_uri).to eq(child_record.uri)
      end
    end

    it 'moves a nested child up a level' do
      visit "#{edit_path}#{nested_child_record_hash}"
      wait_for_ajax
      enable_reorder_mode

      before_order = root_child_uris

      open_move_menu_for_node(nested_child_record)
      click_move_menu_action('up-level')
      wait_for_reorder_idle

      aggregate_failures do
        expect(child_uris_for(child_record.uri)).not_to include(nested_child_record.uri)
        expect(root_child_uris).to eq(before_order + [nested_child_record.uri])
        expect(current_uri).to eq(nested_child_record.uri)
      end
    end

    it 'moves a root-level child down into a sibling as last child' do
      open_move_menu_for_node(child_record)
      click_move_menu_action(
        'down-into',
        target_node_id: infinite_tree_node_id_for(sibling2)
      )
      wait_for_reorder_idle

      aggregate_failures do
        expect(root_child_uris).not_to include(child_record.uri)
        expect(child_uris_for(sibling2.uri).last).to eq(child_record.uri)
        expect(current_uri).to eq(child_record.uri)
      end
    end

    it 'moves only the current row even when multiple rows are selected' do
      install_accept_children_capture
      before_order = root_child_uris

      select_tree_row(sibling2)
      meta_click_row(child_record.uri)
      meta_click_row(sibling3.uri)

      aggregate_failures do
        expect(page).to have_css("li.node[data-uri='#{sibling2.uri}'].current")
        expect(page).to have_css("li.node[data-uri='#{child_record.uri}'].multiselected")
        expect(page).to have_css("li.node[data-uri='#{sibling3.uri}'].multiselected")
      end

      click_infinite_tree_toolbar_move_menu
      click_move_menu_action('up')
      wait_for_reorder_idle

      request = accept_children_requests.last
      expect(request).not_to be_nil

      aggregate_failures do
        expect(root_child_uris).to eq(
          expected_sibling_order_after_move(before_order, sibling2.uri, -1)
        )
        expect(current_uri).to eq(sibling2.uri)
        expect(request['body']).to include(
          "children%5B%5D=#{ERB::Util.url_encode(sibling2.uri)}"
        )
        expect(request['body']).not_to include(
          "children%5B%5D=#{ERB::Util.url_encode(child_record.uri)}"
        )
        expect(request['body']).not_to include(
          "children%5B%5D=#{ERB::Util.url_encode(sibling3.uri)}"
        )
      end
    end
  end
end

RSpec.shared_examples 'cutting and pasting in reorder mode' do
  it 'pastes cut rows into a child destination using the child accept_children path' do
    install_accept_children_capture
    enable_reorder_mode

    select_tree_row(child_record)
    click_tree_row(sibling3.uri)
    click_infinite_tree_toolbar_cut
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include(frontend_accept_children_path_for(child_record))
      expect(request['body']).to include(
        "children%5B%5D=#{ERB::Util.url_encode(sibling3.uri)}"
      )
    end
  end

  it 'pastes cut rows as children of the root using the root accept_children path' do
    install_accept_children_capture
    visit "#{edit_path}#{child_record_hash}"
    wait_for_ajax

    enable_reorder_mode
    click_infinite_tree_toolbar_cut

    select_tree_row(root_record)
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include(frontend_accept_children_path_for(root_record))
      expect(request['body']).to include(
        "children%5B%5D=#{ERB::Util.url_encode(child_record.uri)}"
      )
      expect(page).to have_no_css('li.node.cut')
    end
  end

  it 'pastes only the parent when both parent and child are cut' do
    install_accept_children_capture
    enable_reorder_mode
    expand_tree_node(sibling2.uri)
    wait_for_ajax

    page.execute_script(<<~JS)
      (function() {
        var container = document.querySelector('#infinite-tree-container');
        var parent = document.querySelector("li.node[data-uri='#{sibling2.uri}']");
        var child = document.querySelector("li.node[data-uri='#{nested_under_sibling2.uri}']");
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

    select_tree_row(sibling3)
    click_infinite_tree_toolbar_paste

    request = accept_children_requests.last
    expect(request).not_to be_nil

    aggregate_failures do
      expect(request['url']).to include(frontend_accept_children_path_for(sibling3))
      expect(request['body']).to include(
        "children%5B%5D=#{ERB::Util.url_encode(sibling2.uri)}"
      )
      expect(request['body']).not_to include(
        "children%5B%5D=#{ERB::Util.url_encode(nested_under_sibling2.uri)}"
      )
      expect(page).to have_no_css('li.node.cut')
    end
  end
end

RSpec.shared_examples 'dragging and dropping in reorder mode' do
  before do
    enable_reorder_mode
    install_accept_children_capture
  end

  after do
    wait_for_reorder_idle if page.has_css?('#infinite-tree-container')
  end

  it 'persists a same-parent top-edge drop with adjusted index' do
    before_order = root_child_uris
    source_uri = before_order.first
    target_uri = before_order.last
    expected_order = before_order - [source_uri]
    expected_index = expected_order.index(target_uri)
    expected_order.insert(expected_index, source_uri)

    drag_to_top(source_uri: source_uri, target_uri: target_uri, pause_ms: 0)
    wait_for_reorder_idle

    params = last_accept_children_params

    aggregate_failures do
      expect(params['children']).to eq([source_uri])
      expect(params['index']).to eq(expected_index.to_s)
      expect(root_child_uris).to eq(expected_order)
      expect(current_uri).to eq(root_record.uri)
      expect(page.current_url).to include(root_hash)
    end
  end

  it 'persists an into-edge drop as a child of the target row' do
    drag_into(source_uri: child_record.uri, target_uri: sibling3.uri, pause_ms: 0)
    wait_for_reorder_idle

    aggregate_failures do
      expect(last_accept_children_params['children']).to eq([child_record.uri])
      expect(root_child_uris).not_to include(child_record.uri)
      expect(child_uris_for(sibling3.uri)).to include(child_record.uri)
      expect(current_uri).to eq(root_record.uri)
    end
  end
end

RSpec.shared_examples 'selecting multiple records in reorder mode' do
  context 'when reorder mode is on' do
    before do
      enable_reorder_mode
      wait_for_reorder_mode_ready
    end

    it 'toggles .reorder-mode on the tree container' do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
    end

    it 'adds rows with meta key and excludes the root from selection' do
      meta_click_row(child_record.uri)

      aggregate_failures do
        expect(page).to have_css("li.node[data-uri='#{child_record.uri}'].multiselected")
        expect(selection_uris).to eq([child_record.uri])
        expect(page).to have_no_css('li.node.root.multiselected')
      end
    end

    it 'starts a fresh selection after a successful reorder rebuild' do
      meta_click_row(child_record.uri)
      expect(selection_uris).to eq([child_record.uri])

      drag_into(source_uri: child_record.uri, target_uri: sibling3.uri, pause_ms: 0)
      wait_for_reorder_idle

      expect(page).to have_no_css('#infinite-tree-container .node.multiselected')

      meta_click_row(sibling2.uri)

      aggregate_failures do
        expect(selection_uris).to eq([sibling2.uri])
        expect(page).to have_css(
          '#infinite-tree-container .node.multiselected',
          count: 1,
          visible: :all
        )
      end
    end

    it 'does not send rows detached by the rebuild to accept_children' do
      install_accept_children_capture

      meta_click_row(child_record.uri)
      drag_into(source_uri: child_record.uri, target_uri: sibling3.uri, pause_ms: 0)
      wait_for_reorder_idle

      meta_click_row(sibling2.uri)
      click_infinite_tree_toolbar_cut
      select_tree_row(sibling3)
      click_infinite_tree_toolbar_paste
      wait_for_reorder_idle

      expect(last_accept_children_params['children']).to eq([sibling2.uri])
    end
  end
end

# Product-level reorder mode contract for Infinite Tree edit views (Classifications,
# Digital Objects, etc.). Ported from reorder_mode_spec.rb legacy LargeTree examples.
RSpec.shared_examples 'supporting infinite tree reorder mode' do
  before(:each) do
    visit "/#{@collection_path}/#{@parent.id}/edit"
    wait_for_infinite_tree_pane_ready
    expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
    enable_reorder_mode
    wait_for_reorder_mode_ready
  end

  it 'allows enabling reorder mode' do
    aggregate_failures do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
      expect(find('.js-itree-toolbar-reorder-toggle').text)
        .to eq(I18n.t('actions.reorder_active'))
    end
  end

  it 'returns to non-reorder mode when disabled' do
    disable_reorder_mode

    aggregate_failures do
      expect(find('.js-itree-toolbar-reorder-toggle').text)
        .to eq(I18n.t('actions.enable_reorder'))
      expect(page).to have_no_css('#infinite-tree-container.reorder-mode')
    end
  end

  it 'presents toolbar buttons in correct order' do
    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css(
          '.js-itree-toolbar-reorder-toggle',
          text: I18n.t('actions.reorder_active')
        )
        expect(page).to have_css('.js-itree-toolbar-cut', text: I18n.t('actions.cut'))
        expect(page).to have_css('.js-itree-toolbar-paste', text: I18n.t('actions.paste'))
        expect(page).to have_css('.js-itree-toolbar-move-toggle', text: I18n.t('actions.move'))
        expect(page).to have_css(
          '.js-itree-toolbar-finish-editing',
          text: I18n.t('actions.finish_editing')
        )
        expect(page).to have_css('.js-itree-toolbar-expand-mode', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-collapse-tree', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-add-child', visible: :hidden)
      end
    end
  end

  it 'hides non-reorder actions while reorder mode is active' do
    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_no_button(I18n.t('actions.expand_tree_mode_on'))
        expect(page).to have_no_button(I18n.t('actions.collapse_tree'))
        expect(page).to have_no_button(I18n.t('actions.rapid_data_entry'))
      end
    end
  end

  it 'shows paste control in reorder mode before any cut action' do
    aggregate_failures do
      expect(page).to have_css('.js-itree-toolbar-paste')
      expect_infinite_tree_toolbar_paste_enabled(false)
      expect(page).to have_no_css('#infinite-tree-container li.node.cut', visible: :all)
    end
  end

  it 'cuts the current row and enables paste' do
    select_tree_row(@children.first)
    click_infinite_tree_toolbar_cut

    aggregate_failures do
      expect(page).to have_css(
        "li.node.cut[data-uri='#{@children.first.uri}']",
        visible: :all
      )
      select_tree_row(@children.last)
      expect_infinite_tree_toolbar_paste_enabled(true)
    end
  end

  it 'does not cut the root row' do
    child_uri = @children.first.uri

    select_tree_row(@children.first)
    click_infinite_tree_toolbar_cut
    expect(page).to have_css("li.node.cut[data-uri='#{child_uri}']", visible: :all)

    select_tree_row(@parent)
    click_infinite_tree_toolbar_cut

    aggregate_failures do
      expect(page).to have_no_css("li.node.root.cut[data-uri='#{@parent.uri}']", visible: :all)
      expect(page).to have_css("li.node.cut[data-uri='#{child_uri}']", visible: :all)
    end
  end

  it 'shows move action for non-root rows only' do
    expect(page).to have_css('.js-itree-toolbar-move-toggle.disabled')

    select_tree_row(@children.first)

    expect(page).to have_css('.js-itree-toolbar-move-toggle:not(.disabled)')
  end

  it 'persists selected drop behavior across reloads' do
    skip 'InfiniteTree uses drag-and-drop hitboxes; legacy drop-behavior radios are not shown'
  end

  it 'hides root node drag handle' do
    root_row = page.find(
      "#infinite-tree-container li.node.root[data-uri='#{@parent.uri}'] > .node-row"
    )

    aggregate_failures do
      expect(root_row['draggable']).not_to eq('true')
      expect(root_row).to have_no_css('.node-column[data-column="drag-handle"] svg')
    end
  end

  it 'shows child nodes drag handle' do
    @children.each do |child|
      child_row = tree_row(child.uri)

      aggregate_failures do
        expect(child_row['draggable']).to eq('true')
        expect(child_row).to have_css(
          '.node-column[data-column="drag-handle"] svg',
          visible: :all
        )
      end
    end
  end
end
