/**
 * InfiniteTreeSelection
 *
 * Owns reorder-mode multi-selection state for the new InfiniteTree. Instantiated
 * only in edit-mode views (the read-only partial never calls new InfiniteTreeSelection()).
 *
 * Selection semantics follow literal Finder/Explorer behavior. See
 * INFINITETREE_MULTISELECT_BEHAVIOR_SPEC.md for the full spec, vocabulary, and
 * the action-time dedupe contract that downstream cut/paste/drag-drop consumers
 * apply before assembling an accept_children payload.
 *
 *   - Cmd/Ctrl + click toggles a row's membership (no clear). Mixed depths and
 *     ancestor/descendant overlap are allowed.
 *   - Shift + click extends the selection from the anchor (last row pushed) through
 *     the clicked row in visible DOM order, inclusive, at any indent level. No
 *     same-level filter, no level promotion.
 *   - Plain click replaces the selection with just the clicked row and does NOT
 *     navigate (capture-phase stopImmediatePropagation prevents InfiniteTree's
 *     bubble-phase .record-title handler from routing).
 *   - mousedown outside the tree/toolbar/resizer without a modifier key clears
 *     transient selection.
 *   - Expanding/collapsing a parent does NOT mutate the selection. Hidden
 *     selected descendants persist in `selected` and retain their .multiselected
 *     class; re-expanding the ancestor reveals them as still-selected.
 *
 * Ancestor/descendant overlap is tolerated in the explicit selection because the
 * downstream effectiveMoveSet(...) filter drops descendants of any selected
 * ancestor before sending the move payload to accept_children. The parent already
 * carries them.
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
   * Toggle membership for an individual row (Cmd/Ctrl + click). Mixed depths
   * and ancestor/descendant overlap are allowed; the downstream move-time
   * dedupe drops subsumed rows when assembling the accept_children payload.
   * @param {HTMLElement} li
   */
  #toggle(li) {
    const idx = this.selected.indexOf(li);

    if (idx !== -1) {
      this.selected.splice(idx, 1);
    } else {
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
   * Shift + click: extend selection from anchor through clicked row in visible
   * DOM order, inclusive, at any indent level. No same-level filter, no level
   * promotion. See INFINITETREE_MULTISELECT_BEHAVIOR_SPEC.md.
   * @param {HTMLElement} li
   */
  #shiftExtend(li) {
    const anchor =
      this.selected.length > 0 ? this.selected[this.selected.length - 1] : null;

    if (!anchor) {
      this.#toggle(li);
      return;
    }

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
      if (this.selected.indexOf(candidate) !== -1) continue;

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
   * Recompute .multiselected classes and rewrite the data-selection-uris
   * ordering mirror on the container.
   */
  #applyClasses() {
    this.containerEl.querySelectorAll('.multiselected').forEach(el => {
      el.classList.remove('multiselected');
    });

    this.selected.forEach(li => li.classList.add('multiselected'));

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
