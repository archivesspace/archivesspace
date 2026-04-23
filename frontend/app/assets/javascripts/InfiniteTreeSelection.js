/**
 * InfiniteTreeSelection
 *
 * Owns reorder-mode multi-selection state for the new InfiniteTree. Instantiated
 * only in edit-mode views (the read-only partial never calls new InfiniteTreeSelection()).
 *
 * Selection semantics mirror legacy largetree_dragdrop.js.erb:
 *   - Cmd/Ctrl + click toggles a row's membership (no clear).
 *   - Shift + click extends the selection from the anchor (last selected row) through
 *     the clicked row, only adding rows at the same indent level as the anchor.
 *   - Plain click replaces the selection with just the clicked row and does NOT
 *     navigate (capture-phase stopImmediatePropagation prevents InfiniteTree's
 *     bubble-phase .record-title handler from routing).
 *   - mousedown outside the tree/toolbar/resizer without a modifier key clears
 *     transient selection.
 *   - Collapsing a parent prunes any selected descendants that are no longer visible.
 *   - Ancestor/descendant rows are locked (.selection-locked) and silently rejected
 *     as selection candidates so later Cut/Paste/Drag-Drop consumers never see an
 *     invalid reparent set.
 *
 * Emits on #infinite-tree-container:
 *   - infiniteTreeSelection:changed { selectedNodes: HTMLElement[], anchorNode: HTMLElement|null }
 *   - infiniteTreeSelection:cleared (no detail)
 *
 * Ordering is also mirrored to #infinite-tree-container[data-selection-uris="uri1,uri2,..."]
 * so manual verification and feature specs can read the ordered selection without
 * evaluating live JS state.
 */
class InfiniteTreeSelection {
  static EVENT_CHANGED = 'infiniteTreeSelection:changed';
  static EVENT_CLEARED = 'infiniteTreeSelection:cleared';

  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.containerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    this.toolbarEl = this.componentEl.querySelector('#infinite-tree-toolbar');
    this.resizerEl = this.componentEl.querySelector('#infinite-tree-resizer');

    if (!this.containerEl || !this.toolbarEl) return;

    this.reorderMode = false;

    /** @type {HTMLElement[]} ordered, most-recent last; anchor = last */
    this.selected = [];

    this.#bindEvents();
  }

  #bindEvents() {
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );

    this.containerEl.addEventListener(
      'click',
      this.#onContainerClickCapture.bind(this),
      true
    );

    this.containerEl.addEventListener(
      'click',
      this.#onContainerClickBubble.bind(this)
    );

    document.addEventListener(
      'mousedown',
      this.#onDocumentMouseDown.bind(this)
    );
  }

  #onReorderModeChanged(e) {
    const enabled = !!(e.detail && e.detail.enabled);

    if (enabled) {
      this.reorderMode = true;
      this.containerEl.classList.add('reorder-mode');
    } else {
      this.reorderMode = false;
      this.containerEl.classList.remove('reorder-mode');
      this.#clearAll();
    }
  }

  /**
   * Capture-phase handler. Runs before InfiniteTree's bubble-phase click handler
   * so stopImmediatePropagation can prevent .record-title routing to the pane.
   * @param {MouseEvent} event
   */
  #onContainerClickCapture(event) {
    if (!this.reorderMode) return;

    if (event.target.closest('.node-expand')) return;

    const row = event.target.closest('.node-row');
    if (!row) return;

    const li = row.closest('li.node');
    if (!li || li.classList.contains('root')) return;
    if (!this.containerEl.contains(li)) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    if (event.metaKey || event.ctrlKey) {
      this.#toggle(li);
    } else if (event.shiftKey) {
      this.#shiftExtend(li);
    } else {
      this.#replaceWithSingle(li);
    }
  }

  /**
   * Bubble-phase handler. Only used to prune hidden rows after InfiniteTree's
   * own .node-expand handler has toggled aria-expanded.
   * @param {MouseEvent} event
   */
  #onContainerClickBubble(event) {
    if (!this.reorderMode) return;
    if (!event.target.closest('.node-expand')) return;

    this.#pruneHidden();
  }

  #onDocumentMouseDown(event) {
    if (!this.reorderMode) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey) return;

    const target = event.target;
    if (!target || target.nodeType !== 1) return;
    if (this.containerEl.contains(target)) return;
    if (this.toolbarEl && this.toolbarEl.contains(target)) return;
    if (this.resizerEl && this.resizerEl.contains(target)) return;

    this.#clearAll();
  }

  /**
   * Toggle membership for an individual row (Cmd/Ctrl + click).
   * @param {HTMLElement} li
   */
  #toggle(li) {
    const idx = this.selected.indexOf(li);

    if (idx !== -1) {
      this.selected.splice(idx, 1);
    } else {
      if (this.#isLockedRelativeToSelection(li)) return;
      this.selected.push(li);
    }

    if (this.selected.length === 0) {
      this.#applyClasses();
      this.#emitCleared();
    } else {
      this.#applyClasses();
      this.#emitChanged();
    }
  }

  /**
   * Shift + click: extend selection from anchor to clicked row, same indent
   * level only (legacy parity).
   * @param {HTMLElement} li
   */
  #shiftExtend(li) {
    const anchor =
      this.selected.length > 0 ? this.selected[this.selected.length - 1] : null;

    if (!anchor) {
      this.#toggle(li);
      return;
    }

    const anchorLevel = this.#getIndentLevel(anchor);
    if (anchorLevel === null) return;

    const all = Array.from(this.containerEl.querySelectorAll('li.node'));
    const anchorIdx = all.indexOf(anchor);
    const targetIdx = all.indexOf(li);
    if (anchorIdx === -1 || targetIdx === -1) return;

    const forward = targetIdx >= anchorIdx;
    const startIdx = forward ? anchorIdx + 1 : targetIdx;
    const endIdx = forward ? targetIdx : anchorIdx - 1;

    let changed = false;

    for (let i = startIdx; i <= endIdx; i++) {
      const candidate = all[i];
      if (!candidate || candidate.classList.contains('root')) continue;
      if (this.#getIndentLevel(candidate) !== anchorLevel) continue;
      if (this.selected.indexOf(candidate) !== -1) continue;
      if (this.#isLockedRelativeToSelection(candidate)) continue;

      this.selected.push(candidate);
      changed = true;
    }

    if (!changed) return;

    this.#applyClasses();
    this.#emitChanged();
  }

  /**
   * Plain click: clear any existing selection and single-select the clicked row.
   * Does not navigate (caller stopped propagation).
   * @param {HTMLElement} li
   */
  #replaceWithSingle(li) {
    this.selected = [li];
    this.#applyClasses();
    this.#emitChanged();
  }

  /**
   * Reset internal state and DOM markers. Emits `cleared` only when there was
   * something to clear (outside-click is a no-op when selection is empty).
   */
  #clearAll() {
    if (this.selected.length === 0) return;

    this.selected = [];
    this.#applyClasses();
    this.#emitCleared();
  }

  /**
   * Drop any selected row that is no longer visible because an ancestor row was
   * collapsed. Mirrors legacy handleCollapseNode.
   */
  #pruneHidden() {
    const kept = this.selected.filter(li => !this.#isRowHidden(li));
    if (kept.length === this.selected.length) return;

    this.selected = kept;

    if (this.selected.length === 0) {
      this.#applyClasses();
      this.#emitCleared();
    } else {
      this.#applyClasses();
      this.#emitChanged();
    }
  }

  /**
   * Recompute .multiselected / .selection-locked classes and rewrite the
   * data-selection-uris ordering mirror on the container.
   */
  #applyClasses() {
    this.containerEl
      .querySelectorAll('.multiselected, .selection-locked')
      .forEach(el => {
        el.classList.remove('multiselected');
        el.classList.remove('selection-locked');
      });

    this.selected.forEach(li => li.classList.add('multiselected'));

    const locked = new Set();

    this.selected.forEach(li => {
      let p = li.parentElement ? li.parentElement.closest('li.node') : null;
      while (p) {
        locked.add(p);
        p = p.parentElement ? p.parentElement.closest('li.node') : null;
      }

      li.querySelectorAll(':scope ol.node-children li.node').forEach(d =>
        locked.add(d)
      );
    });

    locked.forEach(el => {
      if (!el.classList.contains('multiselected')) {
        el.classList.add('selection-locked');
      }
    });

    this.#writeSelectionUrisAttr();
    this.#renderBadges();
  }

  /**
   * Update `.selection-order-badge` text on every row in the tree so that the
   * selected rows show their 1-based position in the selection order. Matches
   * LargeTreeDragDrop#refreshAnnotations parity: only show a numeric badge when
   * more than one row is selected; a single selection leaves every badge empty
   * and the CSS `:not(:empty)` rule hides the pill.
   */
  #renderBadges() {
    this.containerEl.querySelectorAll('.selection-order-badge').forEach(el => {
      el.textContent = '';
    });

    if (this.selected.length <= 1) return;

    this.selected.forEach((li, idx) => {
      const badge = li.querySelector(
        ':scope > .node-row > .node-body > [data-column="drag-handle"] > .selection-order-badge'
      );
      if (badge) badge.textContent = String(idx + 1);
    });
  }

  #writeSelectionUrisAttr() {
    if (this.selected.length === 0) {
      this.containerEl.removeAttribute('data-selection-uris');
      return;
    }

    const uris = this.selected
      .map(li => li.getAttribute('data-uri') || '')
      .join(',');

    this.containerEl.setAttribute('data-selection-uris', uris);
  }

  /**
   * A row is locked if any currently-selected row is its strict ancestor or
   * descendant. Legacy drag-disabled parity at the API level.
   * @param {HTMLElement} li
   * @returns {boolean}
   */
  #isLockedRelativeToSelection(li) {
    for (const sel of this.selected) {
      if (sel === li) continue;
      if (sel.contains(li) || li.contains(sel)) return true;
    }
    return false;
  }

  /**
   * A row is hidden when any strict ancestor li.node is collapsed.
   * @param {HTMLElement} li
   * @returns {boolean}
   */
  #isRowHidden(li) {
    let parent = li.parentElement ? li.parentElement.closest('li.node') : null;

    while (parent) {
      if (parent.getAttribute('aria-expanded') === 'false') return true;
      parent = parent.parentElement
        ? parent.parentElement.closest('li.node')
        : null;
    }

    return false;
  }

  /**
   * @param {HTMLElement} li
   * @returns {number|null}
   */
  #getIndentLevel(li) {
    if (!li || !li.className) return null;

    const match = li.className.match(/indent-level-(\d+)/);

    return match ? parseInt(match[1], 10) : null;
  }

  #emitChanged() {
    this.containerEl.dispatchEvent(
      new CustomEvent(InfiniteTreeSelection.EVENT_CHANGED, {
        bubbles: true,
        detail: {
          selectedNodes: this.selected.slice(),
          anchorNode:
            this.selected.length > 0
              ? this.selected[this.selected.length - 1]
              : null,
        },
      })
    );
  }

  #emitCleared() {
    this.containerEl.dispatchEvent(
      new CustomEvent(InfiniteTreeSelection.EVENT_CLEARED, {
        bubbles: true,
        detail: {},
      })
    );
  }
}
