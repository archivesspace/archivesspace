# frozen_string_literal: true

module InfiniteTreeInteractionHelpers
  # ============================================================================
  # Basic element finders
  # ============================================================================

  def tree_container
    find('#infinite-tree-container')
  end

  def tree_node(uri)
    tree_container.find("li.node[data-uri='#{uri}']")
  end

  def tree_row(uri)
    tree_node(uri).find(':scope > .node-row')
  end

  # ============================================================================
  # Mode toggles
  # ============================================================================

  def enable_reorder_mode
    toggle = find('.js-itree-toolbar-reorder-toggle')
    return if toggle.text == I18n.t('actions.reorder_active')

    toggle.click
    expect(page.document).to have_css('#infinite-tree-container.reorder-mode')
  end

  def disable_reorder_mode
    toggle = find('.js-itree-toolbar-reorder-toggle')
    return if toggle.text == I18n.t('actions.enable_reorder')

    toggle.click
    expect(page.document).to have_no_css('#infinite-tree-container.reorder-mode')
  end

  # @param node_or_uri [Object, String] record with #title or tree node data-uri
  def select_tree_row(node_or_uri)
    title = if node_or_uri.respond_to?(:title)
              node_or_uri.title
            else
              tree_node(node_or_uri).find('.record-title').text
            end

    within '#infinite-tree-container' do
      click_link title
    end
    wait_for_infinite_tree_current_node(node_or_uri.respond_to?(:uri) ? node_or_uri.uri : node_or_uri)
  end

  # Waits until a node is current and the record pane has loaded it. The pane
  # loads the current record twice on page load (ANW-3074), so wait_for_ajax's
  # fixed sleep lets the second load finish too.
  def wait_for_infinite_tree_loaded
    expect(page.document).to have_css('#infinite-tree-container li.node.current', visible: :all)
    wait_for_infinite_tree_pane_ready
    wait_for_ajax
  end

  # Waits for the node to become current and the record pane to finish loading
  # it.  The pane is blocked in the same task that marks the node current, so
  # the pane check can't pass before the load has started.
  def wait_for_infinite_tree_current_node(uri)
    expect(page.document).to have_css("#infinite-tree-container li.node.current[data-uri='#{uri}']", visible: :all)
    wait_for_infinite_tree_pane_ready
  end

  # ============================================================================
  # Tree expansion/collapse
  # ============================================================================

  def expand_tree_node(uri)
    node = tree_node(uri)
    return if node['aria-expanded'] == 'true'

    node.find(':scope > .node-row .node-expand').click
    wait_for_infinite_tree_node_expanded(node)
  end

  # Waits for an expand to finish: the node is marked expanded and its first
  # batch of children (or their placeholders) is rendered.
  def wait_for_infinite_tree_node_expanded(node)
    expect(node).to match_css("[aria-expanded='true']")
    expect(node).to have_css(':scope > .node-children > li', minimum: 1, visible: :all)
  end

  def collapse_tree_node(uri)
    node = tree_node(uri)
    return if node['aria-expanded'] == 'false'

    node.find(':scope > .node-row .node-expand').click
  end

  # ============================================================================
  # Modifier key detection
  # ============================================================================

  def modifier_key
    # InfiniteTreeMultiSelection accepts both meta and ctrl
    # Use :meta on macOS, :control elsewhere for compatibility
    RUBY_PLATFORM.match?(/darwin/) ? :meta : :control
  end

  # ============================================================================
  # Modified clicks using ActionBuilder
  # ============================================================================

  def modified_click(element, key:)
    # Ensure element is in viewport and stable before clicking
    tree_container.scroll_to(element, align: :center)

    # DOCUMENTED EXCEPTION: Use JS to dispatch modifier+click events
    # Selenium ActionBuilder has a known issue on macOS where modifier+click
    # triggers context menus instead of multi-selection. Dispatching synthetic
    # MouseEvent is the only reliable way to test modifier-click behavior.
    modifier_map = {
      meta: 'metaKey',
      control: 'ctrlKey',
      shift: 'shiftKey'
    }

    js_modifier = modifier_map[key] || 'metaKey'

    page.execute_script(<<~JS, element)
      const element = arguments[0];
      const event = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        #{js_modifier}: true,
        button: 0
      });
      element.dispatchEvent(event);
    JS

    # Brief pause to let capture-phase handler process the event and update DOM
    sleep 0.1
  end

  # Plain click on a tree row body (not the record title). In reorder mode
  # InfiniteTreeMultiSelection handles this on mousedown capture: multiselection
  # resets to the clicked row and `.current` is unchanged (no navigation).
  def click_tree_row(uri)
    row = tree_row(uri)
    drag_handle = row.find('.node-column[data-column="drag-handle"]', visible: :all)

    tree_container.scroll_to(row, align: :center)
    drag_handle.click
    sleep 0.1
  end

  def meta_click_row(uri)
    row = tree_row(uri)
    modified_click(row, key: :meta)
  end

  def ctrl_click_row(uri)
    row = tree_row(uri)
    # On macOS, Selenium ActionBuilder's :control doesn't work reliably.
    # Since InfiniteTreeMultiSelection accepts both metaKey and ctrlKey,
    # use :meta on macOS for cross-platform testing.
    key = RUBY_PLATFORM.match?(/darwin/) ? :meta : :control
    modified_click(row, key: key)
  end

  def shift_click_row(uri)
    row = tree_row(uri)
    modified_click(row, key: :shift)
  end

  # Click using the platform-appropriate modifier key
  def modifier_click_row(uri)
    row = tree_row(uri)
    modified_click(row, key: modifier_key)
  end

  # ============================================================================
  # Drag and drop using JavaScript-dispatched events
  # ============================================================================
  # DOCUMENTED EXCEPTION: Use JS to dispatch drag events
  # Similar to modifier-click issue, Selenium ActionBuilder's click_and_hold + move
  # operations on macOS trigger unwanted OS-level behaviors (context menus, system
  # drag overlays). Dispatching synthetic DragEvent is the only reliable cross-platform
  # approach for testing HTML5 drag-and-drop.
  # References:
  # - https://github.com/microsoft/playwright/issues/30891
  # - https://github.com/mozilla/geckodriver/issues/1318

  # Main drag method with edge control
  # edge: :top (10% of row height), :into (50%), :bottom (90%)
  def drag_tree_row(source_uri:, target_uri:, edge: :into, pause_ms: 100)
    source_row = tree_row(source_uri)
    target_row = tree_row(target_uri)

    # Scroll both rows into view
    tree_container.scroll_to(source_row, align: :center)
    tree_container.scroll_to(target_row, align: :center)

    # Calculate clientY position within target for edge detection
    target_rect = target_row.native.rect
    y_ratio = case edge
              when :top then 0.1
              when :into then 0.5
              when :bottom then 0.9
              else 0.5
              end

    # Calculate absolute coordinates for dragover event
    client_x = target_rect.x + (target_rect.width / 2)
    client_y = target_rect.y + (target_rect.height * y_ratio)

    page.execute_script(<<~JS, source_row, target_row, client_x, client_y)
      const source = arguments[0];
      const target = arguments[1];
      const clientX = arguments[2];
      const clientY = arguments[3];

      // Create and dispatch dragstart on source
      const dragstart = new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer()
      });
      source.dispatchEvent(dragstart);

      // Create and dispatch dragover on target with calculated coordinates
      const dragover = new DragEvent('dragover', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: dragstart.dataTransfer
      });
      target.dispatchEvent(dragover);

      // Create and dispatch drop on target
      const drop = new DragEvent('drop', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: dragstart.dataTransfer
      });
      target.dispatchEvent(drop);

      // Create and dispatch dragend on source
      const dragend = new DragEvent('dragend', {
        bubbles: true,
        cancelable: true,
        dataTransfer: dragstart.dataTransfer
      });
      source.dispatchEvent(dragend);
    JS

    # Brief pause for DOM updates
    sleep 0.1
  end

  # Convenience wrappers for complete drag operations
  def drag_to_top(source_uri:, target_uri:, pause_ms: 100)
    drag_tree_row(source_uri: source_uri, target_uri: target_uri, edge: :top, pause_ms: pause_ms)
  end

  def drag_into(source_uri:, target_uri:, pause_ms: 100)
    drag_tree_row(source_uri: source_uri, target_uri: target_uri, edge: :into, pause_ms: pause_ms)
  end

  def drag_to_bottom(source_uri:, target_uri:, pause_ms: 100)
    drag_tree_row(source_uri: source_uri, target_uri: target_uri, edge: :bottom, pause_ms: pause_ms)
  end

  # Individual drag event helpers for testing intermediate states
  # (drag preview, blocked targets, etc.)

  def dragstart_from(uri)
    row = tree_row(uri)
    tree_container.scroll_to(row, align: :center)

    page.execute_script(<<~JS, row)
      const source = arguments[0];
      const dragstart = new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer()
      });
      source.dispatchEvent(dragstart);
    JS

    sleep 0.05
  end

  def dragover_row(uri, y_ratio)
    row = tree_row(uri)
    tree_container.scroll_to(row, align: :center)

    rect = row.native.rect
    client_x = rect.x + (rect.width / 2)
    client_y = rect.y + (rect.height * y_ratio)

    page.execute_script(<<~JS, row, client_x, client_y)
      const target = arguments[0];
      const clientX = arguments[1];
      const clientY = arguments[2];
      
      const dragover = new DragEvent('dragover', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: new DataTransfer()
      });
      target.dispatchEvent(dragover);
    JS

    sleep 0.05
  end

  def drop_row(uri, y_ratio)
    row = tree_row(uri)
    tree_container.scroll_to(row, align: :center)

    rect = row.native.rect
    client_x = rect.x + (rect.width / 2)
    client_y = rect.y + (rect.height * y_ratio)

    page.execute_script(<<~JS, row, client_x, client_y)
      const target = arguments[0];
      const clientX = arguments[1];
      const clientY = arguments[2];
      
      const drop = new DragEvent('drop', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: new DataTransfer()
      });
      target.dispatchEvent(drop);
    JS

    sleep 0.05
  end

  def dispatch_dragend(uri)
    row = tree_row(uri)

    page.execute_script(<<~JS, row)
      const source = arguments[0];
      const dragend = new DragEvent('dragend', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer()
      });
      source.dispatchEvent(dragend);
    JS

    sleep 0.05
  end

  # Drag to root node with edge control
  def drag_to_root(source_uri:, edge: :into, pause_ms: 100)
    source_row = tree_row(source_uri)
    root_row = tree_container.find('li.node.root > .node-row')

    tree_container.scroll_to(source_row, align: :center)
    tree_container.scroll_to(root_row, align: :center)

    root_rect = root_row.native.rect
    y_ratio = case edge
              when :top then 0.1
              when :into then 0.5
              when :bottom then 0.9
              else 0.5
              end

    client_x = root_rect.x + (root_rect.width / 2)
    client_y = root_rect.y + (root_rect.height * y_ratio)

    page.execute_script(<<~JS, source_row, root_row, client_x, client_y)
      const source = arguments[0];
      const target = arguments[1];
      const clientX = arguments[2];
      const clientY = arguments[3];

      const dragstart = new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer()
      });
      source.dispatchEvent(dragstart);

      const dragover = new DragEvent('dragover', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: dragstart.dataTransfer
      });
      target.dispatchEvent(dragover);

      const drop = new DragEvent('drop', {
        bubbles: true,
        cancelable: true,
        clientX: clientX,
        clientY: clientY,
        dataTransfer: dragstart.dataTransfer
      });
      target.dispatchEvent(drop);

      const dragend = new DragEvent('dragend', {
        bubbles: true,
        cancelable: true,
        dataTransfer: dragstart.dataTransfer
      });
      source.dispatchEvent(dragend);
    JS

    sleep 0.1
  end

  # ============================================================================
  # DOM state queries (replaces JS evaluate calls)
  # ============================================================================

  def selection_uris
    # Brief wait for data attribute to be updated by JavaScript
    sleep 0.05
    uris_string = tree_container['data-selection-uris']
    return [] if uris_string.nil? || uris_string.empty?

    uris_string.split(',')
  end

  def root_child_uris
    tree_container
      .all('.root.node > .node-children > li.node', visible: :all)
      .map { |node| node['data-uri'] }
  end

  def child_uris_for(parent_uri)
    tree_node(parent_uri)
      .all(':scope > .node-children > li.node', visible: :all)
      .map { |node| node['data-uri'] }
  end

  def current_uri
    current = tree_container.find('li.node.current', visible: :all)
    current['data-uri']
  rescue Capybara::ElementNotFound
    nil
  end

  # DOCUMENTED EXCEPTION: assigning window.location.hash is the only way to
  # exercise the router's hashchange path (back/forward, manually edited URL)
  # for a node that is not rendered yet.
  def navigate_tree_hash(hash)
    normalized = hash.start_with?('#') ? hash : "##{hash}"
    page.execute_script('window.location.hash = arguments[0];', normalized)
    wait_for_ajax
  end

  def wait_for_reorder_idle
    expect(page).to have_no_css('#infinite-tree-container[data-reorder-move-in-flight]')
  end

  # InfiniteTree uses fetch (not jQuery.ajax) for record pane loading,
  # so wait_for_ajax is insufficient. Wait for pane to be ready.
  def wait_for_infinite_tree_pane_ready
    expect(page).to have_no_css('#infinite-tree-record-pane.blocked', wait: 10)
  end

  # Waits for the record pane form to register an edit: form.js marks the
  # form's toolbar .formchanged on the first change or keyup.
  def wait_for_infinite_tree_record_pane_dirty
    expect(page.document).to have_css('#infinite-tree-record-pane .record-toolbar.formchanged')
  end

  # Runs the block, which submits the record pane form, then waits for the
  # pane's submitted event (sent on success and on validation failure) and for
  # the pane to finish loading the result.  The pane isn't blocked while the
  # submit request is in flight, so waiting for the pane alone could pass early.
  def wait_for_infinite_tree_record_pane_submit
    page.execute_script(<<~JS)
      window.__itreeRecordPaneSubmitted = false;
      document.querySelector('#infinite-tree-record-pane').addEventListener(
        'infiniteTreeRecordPane:submitted',
        () => { window.__itreeRecordPaneSubmitted = true; },
        { once: true }
      );
    JS

    yield

    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script('window.__itreeRecordPaneSubmitted')
    end
    wait_for_infinite_tree_pane_ready
    # A successful save rebuilds the tree and, after Save +1, loads a blank
    # sibling form; those requests follow the submit one after another, so
    # give them time with the fixed sleep in wait_for_ajax.
    wait_for_ajax
  end

  # Holds back the responses of fetches whose URL contains one of
  # `url_fragments` (e.g. a record pane load such as "/resources/1/edit?inline=true")
  # until release_held_fetch is called, so a spec can choose the order in which
  # overlapping requests finish.  Each matching fetch is held separately.
  def hold_fetches(*url_fragments)
    page.execute_script(<<~JS, url_fragments)
      var fragments = arguments[0];
      var originalFetch = window.fetch.bind(window);

      window.__itreeHeldFetches = [];

      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        var request = originalFetch(input, init);
        var fragment = fragments.find(function(f) { return url.indexOf(f) !== -1; });

        if (!fragment) return request;

        var held = { fragment: fragment, released: false, delivered: false };
        window.__itreeHeldFetches.push(held);

        return new Promise(function(resolve, reject) {
          held.release = function() {
            held.released = true;
            request.then(function(response) {
              // Mark delivered once the caller has read the body and run the
              // code that follows it in the same task (rendering the pane).
              var text = response.text.bind(response);
              response.text = function() {
                return text().then(function(body) {
                  setTimeout(function() { held.delivered = true; }, 0);
                  return body;
                });
              };
              resolve(response);
            }, reject);
          };
        });
      };
    JS
  end

  # Waits until a fetch matching `url_fragment` has been issued and is being held.
  def wait_for_held_fetch(url_fragment)
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script(<<~JS)
        (window.__itreeHeldFetches || []).some(function(h) {
          return h.fragment === #{url_fragment.to_json} && !h.released;
        })
      JS
    end
  end

  # Releases the oldest held fetch matching `url_fragment` and waits until its
  # caller has handled the response.
  def release_held_fetch(url_fragment)
    wait_for_held_fetch(url_fragment)

    page.execute_script(<<~JS, url_fragment)
      var fragment = arguments[0];
      var held = window.__itreeHeldFetches.find(function(h) {
        return h.fragment === fragment && !h.released;
      });
      window.__itreeReleasedFetch = held;
      held.release();
    JS

    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script('window.__itreeReleasedFetch.delivered')
    end
  end

  # Wait for an inline edit form to finish loading in the record pane.
  # form_prefix is the record type form id prefix (e.g. 'resource', 'archival_object').
  def wait_for_infinite_tree_inline_edit_form(form_prefix:)
    pane = '#infinite-tree-record-pane'
    explicit_form_id = "#{form_prefix}_form"
    form_context_id = "form_#{form_prefix}"

    aggregate_failures do
      expect(page).to have_no_css("#{pane}.blocked")
      expect(page).to have_css(
        "#{pane} ##{explicit_form_id}[data-update-monitor-record-uri], " \
        "#{pane} ##{form_context_id}, #{pane} ##{explicit_form_id}",
        wait: 10
      )
      expect(page).to have_css("#{pane} form[data-update-monitor-record-uri]", wait: 10)
    end
  end

  # Select a tree row by record id rather than title text.
  # @param record [Object] record with #uri
  def select_tree_row_by_id(record)
    node_id = infinite_tree_node_id_for(record)
    find("#infinite-tree-container li##{node_id} > .node-row a.record-title").click
    wait_for_infinite_tree_current_node(record.uri)
  end

  # Wait for tree to be fully ready for reorder mode interactions
  def wait_for_reorder_mode_ready
    aggregate_failures do
      expect(page).to have_css('#infinite-tree-container.reorder-mode')
      expect(page).to have_no_css('#infinite-tree-record-pane.blocked')
    end
  end

  # ============================================================================
  # Tree hash helpers
  # ============================================================================

  def tree_hash_for(uri)
    parts = uri.split('/')
    "tree::#{parts[-2].sub(/s$/, '')}_#{parts[-1]}"
  end

  # DOM id for a tree row (e.g. archival_object_123, resource_456).
  # @param record [Object] record with a #uri
  def infinite_tree_node_id_for(record)
    uri = record.respond_to?(:uri) ? record.uri : record.to_s
    parts = uri.split('/')
    type = parts[-2].sub(/s$/, '')
    "#{type}_#{parts[-1]}"
  end

  def infinite_tree_current_node_selector(record)
    "#infinite-tree-container li##{infinite_tree_node_id_for(record)}.current"
  end

  # ============================================================================
  # Toolbar expand / collapse (Auto-Expand All, Collapse Tree)
  # ============================================================================

  # Auto-expand uses fetch and timers; jQuery.active does not reflect completion.
  def wait_for_infinite_tree_auto_expand_toolbar_idle
    expect(page).to have_css(
      '.js-itree-toolbar-expand-mode:not(.disabled):not([disabled])',
      wait: 15
    )
  end

  def wait_for_infinite_tree_auto_expand_mode_on
    aggregate_failures do
      expect(page).to have_css('#infinite-tree-container.expand-all', wait: 10)
      expect(page).to have_css('.js-itree-toolbar-expand-mode.btn-success', wait: 10)
    end
    wait_for_infinite_tree_auto_expand_toolbar_idle
  end

  def wait_for_infinite_tree_auto_expand_mode_off
    aggregate_failures do
      expect(page).to have_css('#infinite-tree-container:not(.expand-all)', wait: 10)
      expect(page).to have_no_css('.js-itree-toolbar-expand-mode.btn-success', wait: 10)
    end
    wait_for_infinite_tree_auto_expand_toolbar_idle
  end

  def wait_for_infinite_tree_collapsed
    expect(page).to have_no_css(
      '#infinite-tree-container li.node[aria-expanded="true"]:not(.root)',
      wait: 15
    )
    wait_for_infinite_tree_auto_expand_toolbar_idle
  end

  def click_infinite_tree_toolbar_enable_auto_expand
    return if page.has_css?('#infinite-tree-container.expand-all', wait: 0)

    find('.js-itree-toolbar-expand-mode').click
    wait_for_infinite_tree_auto_expand_mode_on
  end

  def click_infinite_tree_toolbar_disable_auto_expand
    return unless page.has_css?('#infinite-tree-container.expand-all', wait: 0)

    find('.js-itree-toolbar-expand-mode').click
    wait_for_infinite_tree_auto_expand_mode_off
  end

  def click_infinite_tree_toolbar_collapse_tree
    find('.js-itree-toolbar-collapse-tree').click
    wait_for_infinite_tree_auto_expand_mode_off
    wait_for_infinite_tree_collapsed
  end

  # ============================================================================
  # Toolbar inline create helpers
  # ============================================================================

  def click_infinite_tree_toolbar_add_child
    find('.js-itree-toolbar-add-child').click
    wait_for_infinite_tree_pane_ready
  end

  def click_infinite_tree_toolbar_add_sibling
    find('.js-itree-toolbar-add-sibling').click
    wait_for_infinite_tree_pane_ready
  end

  def click_infinite_tree_toolbar_add_duplicate
    find('.js-itree-toolbar-add-duplicate').click
    wait_for_infinite_tree_pane_ready
  end

  def cancel_infinite_tree_record_pane_form
    within('#infinite-tree-record-pane') { find('.btn-cancel').click }
    wait_for_infinite_tree_pane_ready
  end

  def install_inline_create_fetch_capture
    page.execute_script(<<~JS)
      window.__itreeInlineCreateRequests = [];
      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/new?') !== -1) {
          window.__itreeInlineCreateRequests.push(url);
        }
        return originalFetch(input, init);
      };
    JS
  end

  def last_inline_create_request_params
    url = page.evaluate_script(
      'window.__itreeInlineCreateRequests[window.__itreeInlineCreateRequests.length - 1]'
    )
    return {} if url.nil? || url.empty?

    uri = URI.parse(url)
    Hash[URI.decode_www_form(uri.query || '')]
  end

  def anchor_tree_position(record)
    page.find(
      "#infinite-tree-container li##{infinite_tree_node_id_for(record)}"
    )['data-tree-position'].to_i
  end

  def anchor_parent_record_id(record)
    page.find(
      "#infinite-tree-container li##{infinite_tree_node_id_for(record)}"
    )['data-tree-parent-record-id']
  end

  def fill_invalid_digital_object_component_fields(now)
    fill_in 'digital_object_component_component_id_', with: "Invalid #{now}"
  end

  def fill_invalid_classification_term_fields(_now)
    # Leave required fields blank.
  end

  # @param title [String]
  # @param form_prefix [String] record form id prefix (e.g. 'archival_object')
  # @param level [String, nil] level-of-description label when the form has a level field
  def fill_and_save_new_child_record(title:, form_prefix:, level: nil)
    fill_in "#{form_prefix}_title_", with: title
    select level, from: "#{form_prefix}_level_" if level

    save_label = I18n.t("#{form_prefix}._frontend.action.save")
    wait_for_infinite_tree_record_pane_submit { find('button', text: save_label, match: :first).click }
  end

  def click_infinite_tree_create_plus_one
    wait_for_infinite_tree_record_pane_submit { find('#createPlusOne', match: :first).click }
  end

  # Fill hierarchy-specific required fields for a valid inline child create.
  # @param child_type [String] e.g. 'digital_object_component', 'classification_term'
  def fill_valid_inline_child_fields(child_type:, title:, level: 'Item')
    case child_type
    when 'archival_object'
      fill_in 'archival_object_title_', with: title
      select level, from: 'archival_object_level_'
    when 'digital_object_component'
      fill_in 'digital_object_component_title_', with: title
      fill_in 'digital_object_component_component_id_', with: title
    when 'classification_term'
      fill_in 'classification_term_title_', with: title
      fill_in 'classification_term_identifier_', with: "id-#{title}"
    else
      raise ArgumentError, "unsupported child_type: #{child_type}"
    end
  end

  def fill_invalid_archival_object_fields(_now)
    # Leave required fields blank.
  end

  def saved_child_id_from_pane
    within('#infinite-tree-record-pane') do
      find('#uri', visible: :all).value.split('/').last.to_i
    end
  end

  def wait_for_infinite_tree_ready_for_rde
    aggregate_failures do
      expect(page).to have_css(
        '#infinite-tree-container li.node.current[data-uri]',
        visible: true
      )
      expect(page).to have_css(
        '#infinite-tree-toolbar .js-itree-toolbar-rde:not(.disabled)',
        visible: true
      )
      expect(page).to have_css('#infinite-tree-record-pane:not(.blocked)')
    end
  end

  def open_infinite_tree_rapid_data_entry_modal
    wait_for_infinite_tree_ready_for_rde

    within '#infinite-tree-toolbar' do
      find('.js-itree-toolbar-rde:not(.disabled)', visible: true).click
    end

    aggregate_failures do
      expect(page).to have_css('#rapidDataEntryModal', visible: true)
      expect(page).to have_css('#rapidDataEntryModal #rde_form', visible: true)
      expect(page).to have_css('#rapidDataEntryModal #rdeTable', visible: true)
    end
  end

  # HTML id for a tree row from a backend record URI.
  def infinite_tree_node_id_for_uri(uri)
    parts = uri.split('/')
    type = parts[-2].sub(/s$/, '')
    "#{type}_#{parts[-1]}"
  end

  # Capture inline create POST submits and record-pane submitSuccess events.
  def install_inline_create_submit_capture
    page.execute_script(<<~JS)
      window.__itreeInlineCreateSubmits = [];
      window.__itreeRecordPaneSubmitEvents = [];

      var recordPane = document.querySelector('#infinite-tree-record-pane');
      if (recordPane) {
        recordPane.addEventListener('infiniteTreeRecordPane:submitSuccess', function(event) {
          window.__itreeRecordPaneSubmitEvents.push(event.detail || {});
        });
      }

      if (!window.__itreeInlineCreateFetchPatched) {
        window.__itreeInlineCreateFetchPatched = true;
        window.__itreeOriginalFetch = window.fetch.bind(window);
        window.fetch = function(input, init) {
          var url = typeof input === 'string' ? input : input.url;
          var method = (init && init.method ? init.method : 'GET').toUpperCase();
          var isCreatePost = method === 'POST' && url && url.indexOf('/accept_children') === -1 && (
            url.indexOf('/archival_objects') !== -1 ||
            url.indexOf('/digital_object_components') !== -1 ||
            url.indexOf('/classification_terms') !== -1
          );

          if (isCreatePost) {
            var plusOne = false;
            var body = init && init.body;
            if (body instanceof FormData) {
              plusOne = body.has('plus_one');
            }
            window.__itreeInlineCreateSubmits.push({ url: url, plusOne: plusOne });
          }

          return window.__itreeOriginalFetch(input, init);
        };
      }
    JS
  end

  def last_inline_create_submit_detail
    page.evaluate_script(
      'window.__itreeInlineCreateSubmits[window.__itreeInlineCreateSubmits.length - 1] || null'
    )
  end

  def last_record_pane_submit_success_detail
    page.evaluate_script(
      'window.__itreeRecordPaneSubmitEvents[window.__itreeRecordPaneSubmitEvents.length - 1] || null'
    )
  end

  def click_infinite_tree_toolbar_cut
    find('.js-itree-toolbar-cut').click
  end

  def click_infinite_tree_toolbar_paste
    find('.js-itree-toolbar-paste').click
    wait_for_reorder_idle
  end

  def expect_infinite_tree_toolbar_cut_enabled(enabled = true)
    if enabled
      expect(page).to have_no_css('.js-itree-toolbar-cut.disabled[disabled]')
    else
      expect(page).to have_css('.js-itree-toolbar-cut.disabled[disabled]')
    end
  end

  def expect_infinite_tree_toolbar_paste_enabled(enabled = true)
    if enabled
      expect(page).to have_no_css('.js-itree-toolbar-paste.disabled[disabled]')
    else
      expect(page).to have_css('.js-itree-toolbar-paste.disabled[disabled]')
    end
  end

  def expect_infinite_tree_reorder_toolbar_for_root(config)
    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.reorder_active'))
        expect(page).to have_css('.js-itree-toolbar-cut', text: I18n.t('actions.cut'))
        expect(page).to have_css('.js-itree-toolbar-paste', text: I18n.t('actions.paste'))
        expect(page).to have_css('.js-itree-toolbar-move-toggle', text: I18n.t('actions.move'))
        expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))

        expect_infinite_tree_toolbar_cut_enabled(false)
        expect_infinite_tree_toolbar_paste_enabled(false)
        expect_infinite_tree_toolbar_move_enabled(false)

        expect(page).to have_css('.js-itree-toolbar-expand-mode', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-collapse-tree', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-add-child', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-add-sibling', visible: :hidden)

        if config[:supports_bulk_import]
          expect(page).to have_css('.js-itree-toolbar-load-bulk', visible: :hidden)
          expect(page).to have_css('#load_via_spreadsheet_help_icon', visible: :hidden)
        else
          expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
          expect(page).to have_no_css('#load_via_spreadsheet_help_icon')
        end

        if config[:supports_rde]
          expect(page).to have_css('.js-itree-toolbar-rde', visible: :hidden)
        else
          expect(page).to have_no_css('.js-itree-toolbar-rde')
        end

        unless config[:supports_add_duplicate]
          expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
        end
      end
    end

    expect(page).to have_no_css('#infinite-tree-container li.node.cut', visible: :all)
  end

  def expect_infinite_tree_reorder_toolbar_for_child(config)
    within '#infinite-tree-toolbar' do
      aggregate_failures do
        expect(page).to have_css('.js-itree-toolbar-reorder-toggle', text: I18n.t('actions.reorder_active'))
        expect(page).to have_css('.js-itree-toolbar-finish-editing', text: I18n.t('actions.finish_editing'))

        expect_infinite_tree_toolbar_cut_enabled(true)
        expect_infinite_tree_toolbar_paste_enabled(false)
        expect_infinite_tree_toolbar_move_enabled(true)

        expect(page).to have_css('.js-itree-toolbar-expand-mode', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-collapse-tree', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-add-child', visible: :hidden)
        expect(page).to have_css('.js-itree-toolbar-add-sibling', visible: :hidden)

        if config[:supports_bulk_import]
          expect(page).to have_css('.js-itree-toolbar-load-bulk', visible: :hidden)
          expect(page).to have_css('#load_via_spreadsheet_help_icon', visible: :hidden)
        else
          expect(page).to have_no_css('.js-itree-toolbar-load-bulk')
          expect(page).to have_no_css('#load_via_spreadsheet_help_icon')
        end

        if config[:supports_rde]
          expect(page).to have_css('.js-itree-toolbar-rde', visible: :hidden)
        else
          expect(page).to have_no_css('.js-itree-toolbar-rde')
        end

        unless config[:supports_add_duplicate]
          expect(page).to have_no_css('.js-itree-toolbar-add-duplicate')
        end
      end
    end
  end

  # ============================================================================
  # Toolbar move menu helpers
  # ============================================================================

  def click_infinite_tree_toolbar_move_menu
    find('.js-itree-toolbar-move-toggle').click
  end

  def expect_infinite_tree_toolbar_move_enabled(enabled = true)
    if enabled
      expect(page).to have_no_css('.js-itree-toolbar-move-toggle.disabled[disabled]')
    else
      expect(page).to have_css('.js-itree-toolbar-move-toggle.disabled[disabled]')
    end
  end

  # @param action [String] move menu action key (e.g. 'up', 'down', 'up-level')
  # @param enabled [Boolean] whether the action should be enabled
  def move_menu_has_action?(action, enabled: true)
    state_selector = enabled ? ':not([disabled])' : '[disabled]'
    page.has_css?(
      ".js-itree-toolbar-move-menu button[data-move-action='#{action}']:not([data-target-node-id])#{state_selector}"
    )
  end

  # @param action [String] move menu action key
  # @param target_node_id [String, nil] DOM id for Down Into submenu target
  def click_move_menu_action(action, target_node_id: nil)
    within '.js-itree-toolbar-move-menu' do
      if target_node_id
        find('button[data-move-action="down-into"]:not([data-target-node-id])').hover
        find(
          "button[data-move-action='down-into'][data-target-node-id='#{target_node_id}']",
          visible: true
        ).click
      else
        find(
          "button[data-move-action='#{action}']:not([data-target-node-id])",
          match: :first
        ).click
      end
    end
    wait_for_reorder_idle
  end

  def open_move_menu_for_node(node_or_uri)
    select_tree_row(node_or_uri)
    click_infinite_tree_toolbar_move_menu
  end

  # URIs listed in the Down Into submenu for the currently open move menu.
  def down_into_submenu_target_uris
    page.evaluate_script(<<~JS)
      (function() {
        return Array.prototype.map.call(
          document.querySelectorAll('.js-itree-toolbar-move-menu .move-node-into-menu [data-target-node-id]'),
          function(btn) {
            var targetId = btn.getAttribute('data-target-node-id');
            var targetNode = document.getElementById(targetId);
            return targetNode ? targetNode.getAttribute('data-uri') : null;
          }
        ).filter(Boolean);
      })();
    JS
  end
end

# ============================================================================
# Request spy helpers (JS-based - documented exceptions)
# ============================================================================

module InfiniteTreeRequestSpies
  # Install fetch wrapper to capture accept_children requests
  def install_accept_children_capture
    page.execute_script(<<~JS)
      window.__itreeAcceptChildrenRequests = [];
      window.__itreeReorderEvents = [];

      var originalFetch = window.fetch.bind(window);
      window.fetch = function(input, init) {
        var url = typeof input === 'string' ? input : input.url;
        if (url && url.indexOf('/accept_children') !== -1) {
          window.__itreeAcceptChildrenRequests.push({
            url: url,
            method: init && init.method,
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
          var detail = event.detail || {};
          window.__itreeReorderEvents.push({
            name: event.type,
            reason: detail.reason || null,
            childUris: detail.childUris || [],
            targetParentUri: detail.targetParentUri || null,
            rawIndex: detail.rawIndex,
            adjustedIndex: detail.adjustedIndex,
            error: detail.error || null
          });
        });
      });
    JS
  end

  def accept_children_requests
    page.evaluate_script('window.__itreeAcceptChildrenRequests || []')
  end

  def accept_children_request_count
    page.evaluate_script('window.__itreeAcceptChildrenRequests.length')
  end

  def last_accept_children_request
    page.evaluate_script('window.__itreeAcceptChildrenRequests[window.__itreeAcceptChildrenRequests.length - 1] || null')
  end

  def last_accept_children_params
    page.evaluate_script(<<~JS)
      (function() {
        var req = window.__itreeAcceptChildrenRequests[window.__itreeAcceptChildrenRequests.length - 1];
        if (!req) return null;
        var params = new URLSearchParams(req.body);
        return {
          children: params.getAll('children[]'),
          index: params.get('index')
        };
      })()
    JS
  end

  # Capture custom events dispatched on the tree container. Needed for events
  # that do not bubble (e.g. infiniteTreeRouter:setCurrentNode), which cannot be
  # observed from `document`.
  def install_tree_event_capture(*event_names)
    page.execute_script(<<~JS, event_names)
      var names = arguments[0];
      var container = document.querySelector('#infinite-tree-container');
      if (!container) throw new Error('infinite tree container not found');

      window.__itreeCapturedEvents = window.__itreeCapturedEvents || {};

      names.forEach(function(name) {
        window.__itreeCapturedEvents[name] = [];

        container.addEventListener(name, function(event) {
          var detail = null;
          try {
            detail = event.detail ? JSON.parse(JSON.stringify(event.detail)) : null;
          } catch (e) {
            detail = null;
          }
          window.__itreeCapturedEvents[name].push(detail);
        });
      });
    JS
  end

  def captured_tree_events(name)
    page.evaluate_script(
      "(window.__itreeCapturedEvents && window.__itreeCapturedEvents['#{name}']) || []"
    )
  end

  def tree_event_count(name)
    captured_tree_events(name).length
  end

  def reorder_events(name)
    page.evaluate_script("window.__itreeReorderEvents.filter(function(e) { return e.name === '#{name}'; })")
  end
end
