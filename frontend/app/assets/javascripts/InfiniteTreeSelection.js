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
 *   - Plain click on a record title clears multiselection state, then bubbles
 *     to InfiniteTree's record-title router so the URL hash and page-level
 *     selected record update normally. This is required for the Cut/Paste and
 *     Move workflows where users click a target record after multi-selecting
 *     source rows. Multi-selection itself is driven by non-link row clicks.
 *     Plain mousedown on a non-link row that is not part of the multi-selection
 *     eagerly collapses to that single row so a follow-on drag operates on a
 *     single source; mousedown on an already-multiselected row leaves the set
 *     intact so the whole group can be dragged.
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
 * Selection ordering is mirrored to
 * #infinite-tree-container[data-selection-uris="uri1,uri2,..."] in visible DOM
 * order so manual verification and feature specs can read the ordered selection
 * without evaluating live JS state. Anchor is tracked separately via internal
 * click history and emitted as anchorNode on changed events.
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

    /** @type {HTMLElement[]} ordered by visible DOM position after each mutation */
    this.selected = [];
    /** @type {HTMLElement[]} click history, most-recent last; anchor = last */
    this.pushOrder = [];

    this.#bindEvents();
  }

  #bindEvents() {
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );

    this.containerEl.addEventListener(
      'mousedown',
      this.#onContainerMouseDownCapture.bind(this),
      true
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
   * Capture-phase handler. Intercepts only modifier-key clicks (Cmd/Ctrl/Shift)
   * to drive multi-selection without routing. Plain record-title clicks clear
   * multiselection and then fall through to InfiniteTree's bubble-phase router
   * so navigation still occurs in reorder mode (required for Cut/Paste/Move
   * target selection). Plain non-link click selection state is managed by the
   * mousedown handler.
   * @param {MouseEvent} event
   */
  #onContainerClickCapture(event) {
    if (!this.reorderMode) return;

    if (event.target.closest('.node-expand')) return;

    const onRecordLink = !!event.target.closest('.record-title');
    const hasModifier = event.metaKey || event.ctrlKey || event.shiftKey;
    if (!hasModifier) {
      if (onRecordLink) this.#clearAll();
      return;
    }

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
    }
  }

  /**
   * Capture-phase mousedown handler. Plain mousedown in reorder mode should
   * immediately reset any existing multi-selection to the pressed row so drag
   * start sees the intended single-row source set.
   * @param {MouseEvent} event
   */
  #onContainerMouseDownCapture(event) {
    if (!this.reorderMode) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey) return;
    if (event.button !== 0) return;
    if (event.target.closest('.node-expand')) return;
    if (event.target.closest('.record-title')) return;

    const row = event.target.closest('.node-row');
    if (!row) return;

    const li = row.closest('li.node');
    if (!li || li.classList.contains('root')) return;
    if (!this.containerEl.contains(li)) return;

    // Keep an existing multiselection intact when mousing down on one of its
    // members so a subsequent drag can move the whole set. If this row is not
    // selected, immediately reset to single-select so dragstart sees the
    // intended source row.
    if (this.selected.indexOf(li) !== -1) return;

    this.#replaceWithSingle(li);
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
      const pushIdx = this.pushOrder.indexOf(li);
      if (pushIdx !== -1) this.pushOrder.splice(pushIdx, 1);
    } else {
      this.selected.push(li);
      this.pushOrder.push(li);
      this.#sortSelectedByDom();
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
      this.pushOrder.length > 0
        ? this.pushOrder[this.pushOrder.length - 1]
        : null;

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
      this.pushOrder.push(candidate);
      changed = true;
    }

    if (!changed) return;

    this.#sortSelectedByDom();
    this.#applyClasses();
    this.#emitChanged();
  }

  /**
   * Reset selection to a single row. Invoked from the mousedown capture handler
   * when the pressed row is not part of the current multi-selection so a
   * follow-on drag sees a clean single-row source set. Plain clicks themselves
   * are not intercepted; navigation is handled downstream by the router.
   * @param {HTMLElement} li
   */
  #replaceWithSingle(li) {
    if (this.selected.length === 1 && this.selected[0] === li) return;

    this.selected = [li];
    this.pushOrder = [li];
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
    this.pushOrder = [];
    this.#applyClasses();
    this.#emitCleared();
  }

  #sortSelectedByDom() {
    if (this.selected.length <= 1) return;

    const all = Array.from(this.containerEl.querySelectorAll('li.node'));
    const indexByNode = new Map(all.map((el, i) => [el, i]));

    this.selected.sort(
      (a, b) => (indexByNode.get(a) ?? -1) - (indexByNode.get(b) ?? -1)
    );
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
            this.pushOrder.length > 0
              ? this.pushOrder[this.pushOrder.length - 1]
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
