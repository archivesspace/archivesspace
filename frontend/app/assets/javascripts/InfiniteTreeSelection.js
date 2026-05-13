/**
 * InfiniteTreeSelection
 *
 * Owns reorder-mode multi-selection state for the new InfiniteTree. Instantiated
 * only in edit-mode views (the read-only partial never calls new InfiniteTreeSelection()).
 *
 * Selection semantics use CLICK-ORDER (the sequence in which rows are selected
 * determines their order in move/paste operations). See
 * INFINITETREE_MULTISELECT_ORDER_BASED_RULES.md for the complete stakeholder-facing
 * explanation.
 *
 * Core behaviors:
 *   - Cmd/Ctrl + click toggles a row's membership. New selections append to the
 *     end of the array (preserving click order).
 *   - Shift + click extends from anchor to endpoint in visible order. The range
 *     is appended to the end of the existing selection in the anchor→endpoint
 *     direction.
 *   - Selection order badges (1, 2, 3...) display on each selected row when
 *     multiple rows are selected.
 *   - Plain click on a record title clears multiselection state, then bubbles
 *     to InfiniteTree's record-title router so URL hash updates (required for
 *     Cut/Paste target selection workflow).
 *   - Plain mousedown on a non-link row immediately resets to single-row selection
 *     so drag can operate on the intended source.
 *   - mousedown outside tree/toolbar/resizer without modifier key clears selection.
 *   - Expanding/collapsing a parent does NOT mutate selection. Hidden selected
 *     descendants persist and re-appear when re-expanded.
 *
 * Parent-child mutual exclusion (ancestry-based):
 *   - Child selected → ALL ancestors are locked (cannot be selected)
 *   - Parent selected → ALL descendants are locked (cannot be selected)
 *   - Siblings can always be selected together
 *   - Range selection (Shift+click) skips locked rows, creating visual "holes"
 *   - Ancestor unlocks only when ALL its selected descendants are deselected
 *
 * Action-time behavior:
 *   - Parent selected: carries ALL children (loaded and unloaded) through move
 *   - Children selected: hoisted to destination level (no parent structure preserved)
 *   - effectiveMoveSet(...) filter in downstream consumers (Cut/Paste/DragDrop)
 *     dedupes any remaining redundancy before sending to accept_children
 *
 * Emits on #infinite-tree-container:
 *   - infiniteTreeSelection:changed { selectedNodes: HTMLElement[], anchorNode: HTMLElement|null }
 *   - infiniteTreeSelection:cleared (no detail)
 *
 * Selection ordering is mirrored to #infinite-tree-container[data-selection-uris="uri1,uri2,..."]
 * in click order for manual verification and feature specs.
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

    /** @type {HTMLElement[]} ordered by click/selection sequence */
    this.selected = [];

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
   * Toggle membership for an individual row (Cmd/Ctrl + click). Ancestry-based
   * locking prevents selecting both an ancestor and descendant simultaneously.
   * @param {HTMLElement} li
   */
  #toggle(li) {
    const idx = this.selected.indexOf(li);

    if (idx !== -1) {
      // Deselecting - remove from array
      this.selected.splice(idx, 1);
    } else {
      // Adding - check if locked first
      if (this.#isLockedRelativeToSelection(li)) {
        // Silently reject locked rows
        return;
      }
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
   * Shift + click: extend selection from anchor to endpoint using the
   * "topmost ancestor collapsing" algorithm.
   *
   * Algorithm:
   * 1. Identify "locked-out" nodes: all ancestors of anchor, endpoint, and any already-selected nodes
   * 2. Identify "in-range" candidates: visible nodes strictly between anchor and endpoint, excluding locked-out
   * 3. Apply collapsing: skip in-range nodes that have an explicit ancestor among
   *    already-selected rows, the endpoint, or another in-range topmost row
   * 4. Push: in-range nodes (in anchor→endpoint order) + endpoint
   *
   * The endpoint is always explicitly selected and becomes the new anchor.
   * Descendants of the endpoint (or anchor) fall in the flat DOM slice after an
   * expanded parent; they must not be pushed explicitly even when they sit between
   * anchor and endpoint indices.
   *
   * @param {HTMLElement} li - The endpoint node (shift+clicked)
   */
  #shiftExtend(li) {
    const anchor =
      this.selected.length > 0 ? this.selected[this.selected.length - 1] : null;

    if (!anchor) {
      this.#toggle(li);
      return;
    }

    const endpoint = li;

    if (endpoint.classList.contains('root')) return;
    if (endpoint === anchor) return;
    if (this.#isLockedRelativeToSelection(endpoint)) return;

    const all = Array.from(this.containerEl.querySelectorAll('li.node'));
    const anchorIdx = all.indexOf(anchor);
    const endpointIdx = all.indexOf(endpoint);
    if (anchorIdx === -1 || endpointIdx === -1) return;

    const forward = endpointIdx > anchorIdx;

    // 1. Build "locked-out" set: ancestors of anchor, endpoint, and all already-selected nodes
    const lockedOut = new Set();
    for (const sel of this.selected) {
      this.#addAllAncestors(sel, lockedOut);
    }
    this.#addAllAncestors(endpoint, lockedOut);

    // 2. Collect in-range candidates (nodes strictly between anchor and endpoint)
    const startIdx = forward ? anchorIdx + 1 : endpointIdx + 1;
    const endIdx = forward ? endpointIdx - 1 : anchorIdx - 1;

    const inRangeCandidates = [];
    if (startIdx <= endIdx) {
      for (let i = startIdx; i <= endIdx; i++) {
        const candidate = all[i];
        if (!candidate || candidate.classList.contains('root')) continue;
        if (this.selected.indexOf(candidate) !== -1) continue;
        if (lockedOut.has(candidate)) continue;

        inRangeCandidates.push(candidate);
      }
    }

    // 3. Apply collapsing. Nodes with an explicit ancestor (already selected,
    // endpoint, or another in-range row kept as topmost) become implicit only.
    const candidateSet = new Set(inRangeCandidates);
    const covering = new Set(this.selected);
    if (this.selected.indexOf(endpoint) === -1) {
      covering.add(endpoint);
    }

    const explicitMiddle = [];

    for (const candidate of inRangeCandidates) {
      if (this.#hasAncestorInSet(candidate, covering)) continue;

      let hasInRangeAncestor = false;
      let current = candidate;

      while (current) {
        const parent = this.#getDirectParent(current);
        if (parent && candidateSet.has(parent)) {
          hasInRangeAncestor = true;
          break;
        }
        current = parent;
      }

      if (!hasInRangeAncestor) {
        explicitMiddle.push(candidate);
        covering.add(candidate);
      }
    }

    // 4. Build final list in anchor→endpoint order
    // For backward ranges, reverse middle nodes since they were collected low→high
    if (!forward) {
      explicitMiddle.reverse();
    }

    // Add endpoint unless already selected
    const toAdd = [...explicitMiddle];
    if (this.selected.indexOf(endpoint) === -1) {
      toAdd.push(endpoint);
    }

    if (toAdd.length === 0) return;

    this.selected.push(...toAdd);
    this.#applyClasses();
    this.#emitChanged();
  }

  /**
   * Whether any ancestor of li appears in ancestorSet (walks direct parents only).
   * @param {HTMLElement} li
   * @param {Set<HTMLElement>} ancestorSet
   * @returns {boolean}
   */
  #hasAncestorInSet(li, ancestorSet) {
    let current = li;

    while (current) {
      const parent = this.#getDirectParent(current);
      if (!parent) return false;
      if (ancestorSet.has(parent)) return true;
      current = parent;
    }

    return false;
  }

  /**
   * Add all ancestors of a node to a set.
   * @param {HTMLElement} li
   * @param {Set<HTMLElement>} set
   */
  #addAllAncestors(li, set) {
    let current = li;
    while (current) {
      const parent = this.#getDirectParent(current);
      if (parent) {
        set.add(parent);
        current = parent;
      } else {
        break;
      }
    }
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
   * Recompute visual state classes for all nodes:
   * - .multiselected: explicitly selected nodes (in this.selected array)
   * - .implicitly-multiselected: descendants of selected parents (move with parent, no badge)
   * - .selection-locked: ancestors of selected nodes (cannot be selected)
   *
   * Also rewrites data-selection-uris and renders selection order badges.
   */
  #applyClasses() {
    // Clear existing classes
    this.containerEl
      .querySelectorAll(
        '.multiselected, .implicitly-multiselected, .selection-locked'
      )
      .forEach(el => {
        el.classList.remove(
          'multiselected',
          'implicitly-multiselected',
          'selection-locked'
        );
      });

    this.selected.forEach(li => li.classList.add('multiselected'));

    const implicit = this.#getImplicitlyMultiselectedDescendants();
    implicit.forEach(li => li.classList.add('implicitly-multiselected'));

    const locked = this.#getLockedAncestors();
    locked.forEach(li => li.classList.add('selection-locked'));

    this.#writeSelectionUrisAttr();
    this.#renderBadges();
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

  /** Checkmark shown in the badge slot for implicitly multiselected rows. */
  static IMPLICIT_SELECTION_MARK = '\u2713';

  /**
   * Render selection indicators in each row's .selection-order-badge span.
   * Explicit rows get numeric order (1, 2, 3...); implicit rows get a checkmark.
   * Only shown when selected.length > 1 (SCSS :not(:empty) gates visibility).
   */
  #renderBadges() {
    this.containerEl
      .querySelectorAll('.selection-order-badge')
      .forEach(badge => {
        badge.textContent = '';
        badge.classList.remove('implicit-mark');
      });

    if (this.selected.length <= 1) return;

    this.selected.forEach((li, idx) => {
      const badge = li.querySelector('.selection-order-badge');
      if (badge) {
        badge.textContent = String(idx + 1);
      }
    });

    this.containerEl
      .querySelectorAll('.node.implicitly-multiselected .selection-order-badge')
      .forEach(badge => {
        badge.textContent = InfiniteTreeSelection.IMPLICIT_SELECTION_MARK;
        badge.classList.add('implicit-mark');
      });
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

  /**
   * Get the direct parent li.node of a given node, or null if none.
   * @param {HTMLElement} li
   * @returns {HTMLElement|null}
   */
  #getDirectParent(li) {
    const listEl = li.parentElement;
    if (!listEl || listEl.tagName !== 'OL') return null;
    const parentLi = listEl.parentElement;
    if (!parentLi || !parentLi.classList.contains('node')) return null;
    return parentLi;
  }

  /**
   * Check if a row is locked relative to a selection set.
   * Locked if: ANY ancestor of a selected node, or ANY descendant of a selected node.
   * Uses browser-native .contains() for O(selection_count) performance.
   * @param {HTMLElement} li - The node to check for locking
   * @param {HTMLElement[]|null} selectedSnapshot - Optional selection snapshot, defaults to this.selected
   * @returns {boolean}
   */
  #isLockedRelativeToSelection(li, selectedSnapshot = null) {
    const sel = selectedSnapshot ?? this.selected;

    for (const selectedNode of sel) {
      // Check if li is an ancestor of selectedNode (li contains selectedNode)
      if (li.contains(selectedNode)) return true;

      // Check if li is a descendant of selectedNode (selectedNode contains li)
      if (selectedNode.contains(li)) return true;
    }

    return false;
  }

  /**
   * Get all ancestor nodes that should be visually locked (.selection-locked class).
   * These are nodes that cannot be selected because a descendant is already selected.
   * @returns {Set<HTMLElement>}
   */
  #getLockedAncestors() {
    const locked = new Set();

    for (const selectedNode of this.selected) {
      let current = selectedNode;
      while (current) {
        const parent = this.#getDirectParent(current);
        if (parent) {
          locked.add(parent);
          current = parent;
        } else {
          break;
        }
      }
    }

    return locked;
  }

  /**
   * Get all descendant nodes that are implicitly multiselected (.implicitly-multiselected class).
   * These are nodes that will move with their selected parent but don't get badges.
   * @returns {Set<HTMLElement>}
   */
  #getImplicitlyMultiselectedDescendants() {
    const implicit = new Set();

    for (const selectedNode of this.selected) {
      const descendants = selectedNode.querySelectorAll(':scope li.node');
      descendants.forEach(d => implicit.add(d));
    }

    return implicit;
  }
}
