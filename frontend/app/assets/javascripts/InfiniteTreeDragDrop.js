class InfiniteTreeDragDrop {
  static EVENT_DROP_INTENT = 'infiniteTreeDragDrop:dropIntent';
  static DRAG_PREVIEW_CURSOR_OFFSET = 12;
  static DRAG_PREVIEW_SNAPBACK_DURATION = 300;
  static DRAG_PREVIEW_SNAPBACK_HOLD = 75;
  static DRAG_PREVIEW_SNAPBACK_FADE = 125;

  constructor() {
    this.treeComponentEl = document.getElementById('infinite-tree-component');
    if (!this.treeComponentEl) return;

    this.treeContainerEl = this.treeComponentEl.querySelector(
      '#infinite-tree-container'
    );
    if (!this.treeContainerEl) return;

    this.rootUri = this.treeComponentEl.getAttribute('data-root-uri') || '';
    this.reorderMode = false;
    this.explicitSelectionNodes = [];
    this.dragSelectionNodes = [];
    this.dragEffectiveNodes = [];
    this.dragPreviewEl = null;
    this.dragStartPoint = null;
    this.dragOverHandler = this.#onDocumentDragOver.bind(this);
    this.documentDropHandler = this.#onDocumentDrop.bind(this);
    this.emptyDragImage = null;
    this.activeDropRow = null;
    this.activeDropChildrenList = null;
    this.isDragging = false;
    this.observer = null;

    this.#bindEvents();
  }

  #bindEvents() {
    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );
    this.treeContainerEl.addEventListener(
      InfiniteTreeSelection.EVENT_CHANGED,
      this.#onSelectionChanged.bind(this)
    );
    this.treeContainerEl.addEventListener(
      InfiniteTreeSelection.EVENT_CLEARED,
      this.#onSelectionCleared.bind(this)
    );
    this.treeContainerEl.addEventListener(
      'dragstart',
      this.#onDragStart.bind(this)
    );
    this.treeContainerEl.addEventListener(
      'dragover',
      this.#onDragOver.bind(this)
    );
    this.treeContainerEl.addEventListener('drop', this.#onDrop.bind(this));
    this.treeContainerEl.addEventListener(
      'dragend',
      this.#onDragEnd.bind(this)
    );
  }

  #onReorderModeChanged(event) {
    this.reorderMode = !!(event.detail && event.detail.enabled);
    if (this.reorderMode) {
      this.#refreshDraggables();
      this.#startObserving();
    } else {
      this.#stopObserving();
      this.#disableDraggables();
      this.#cleanupDragState();
    }
  }

  #onSelectionChanged(event) {
    this.explicitSelectionNodes = Array.isArray(event.detail?.selectedNodes)
      ? event.detail.selectedNodes.filter(Boolean)
      : [];
  }

  #onSelectionCleared() {
    this.explicitSelectionNodes = [];
  }

  #refreshDraggables() {
    const rows = this.treeContainerEl.querySelectorAll(
      'li.node:not(.root):not(.js-itree-synthetic-new) > .node-row'
    );

    rows.forEach(row => {
      row.setAttribute('draggable', 'true');
      row.setAttribute('title', 'Drag to reorder');
      row.setAttribute('aria-label', 'Drag to reorder');
    });
  }

  #disableDraggables() {
    this.treeContainerEl
      .querySelectorAll('.node-row[draggable]')
      .forEach(row => {
        row.removeAttribute('draggable');
        row.removeAttribute('title');
        row.removeAttribute('aria-label');
      });
  }

  #startObserving() {
    if (this.observer) return;
    this.observer = new MutationObserver(() => {
      this.#refreshDraggables();
    });
    this.observer.observe(this.treeContainerEl, {
      childList: true,
      subtree: true,
    });
  }

  #stopObserving() {
    if (!this.observer) return;
    this.observer.disconnect();
    this.observer = null;
  }

  #onDragStart(event) {
    if (!this.reorderMode) return;
    const row = event.target.closest(".node-row[draggable='true']");
    if (!row) return;
    if (event.target.closest('.node-expand')) return;

    const sourceLi = row.closest('li.node');
    if (!sourceLi || sourceLi.classList.contains('root')) return;

    // Ensure text selection doesn't become the drag payload when dragging the row.
    if (window.getSelection) {
      const selection = window.getSelection();
      if (selection && typeof selection.removeAllRanges === 'function') {
        selection.removeAllRanges();
      }
    }
    if (event.dataTransfer) {
      event.dataTransfer.setData('text/plain', 'infinite-tree-drag');
    }

    const explicit = this.explicitSelectionNodes.filter(
      node => node && node.isConnected
    );
    const hasSourceInExplicit = explicit.includes(sourceLi);

    this.dragSelectionNodes = hasSourceInExplicit ? explicit : [sourceLi];
    this.dragEffectiveNodes = this.#effectiveMoveSet(this.dragSelectionNodes);
    this.isDragging = true;
    this.dragStartPoint = { x: event.clientX, y: event.clientY };
    this.dragPreviewEl = this.#buildDragPreview(this.dragSelectionNodes);

    this.dragSelectionNodes.forEach(node =>
      node.classList.add('is-being-dragged')
    );

    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', 'infinite-tree-drag');
      event.dataTransfer.setDragImage(this.#getEmptyDragImage(), 0, 0);
    }

    document.addEventListener('dragover', this.dragOverHandler);
    document.addEventListener('drop', this.documentDropHandler);
  }

  /**
   * Returns an invisible element to pass to setDragImage.
   * The browser applies semi-transparency to the drag image, so we pass it
   * an invisible element then render a fully-opaque drag preview instead.
   * @returns {HTMLElement}
   */
  #getEmptyDragImage() {
    if (!this.emptyDragImage) {
      const template = document
        .querySelector('#infinite-tree-empty-drag-image-template')
        .content.cloneNode(true);

      this.emptyDragImage = template.querySelector('div');

      document.body.appendChild(this.emptyDragImage);
    }

    return this.emptyDragImage;
  }

  /**
   * Positions our manually created drag preview near the cursor during drag.
   * @param {DragEvent} event
   */
  #onDocumentDragOver(event) {
    if (!this.isDragging || !this.dragPreviewEl) return;
    event.preventDefault();

    const offset = InfiniteTreeDragDrop.DRAG_PREVIEW_CURSOR_OFFSET;
    this.dragPreviewEl.style.left = `${event.clientX + offset}px`;
    this.dragPreviewEl.style.top = `${event.clientY + offset}px`;
  }

  /**
   * Handles drops outside the tree container.
   * @param {DragEvent} event
   */
  #onDocumentDrop(event) {
    if (!this.isDragging) return;
    event.preventDefault();

    this.#snapBackAndRemoveDragPreview();
    this.#cleanupDragState();
  }

  #onDragOver(event) {
    if (!this.isDragging || !this.reorderMode) return;
    this.#clearActiveDropIndicators();

    const row = event.target.closest('.node-row');
    if (!row) return;

    const targetLi = row.closest('li.node');
    if (!targetLi || targetLi.classList.contains('js-itree-synthetic-new'))
      return;
    if (
      targetLi.hasAttribute('data-batch-placeholder') ||
      targetLi.getAttribute('data-observe-next-batch') === 'true'
    ) {
      return;
    }

    const blocked = this.#isBlockedTarget(targetLi);
    const edge = InfiniteTreeDropHitbox.standardHitbox(
      { x: event.clientX, y: event.clientY },
      row.getBoundingClientRect()
    );

    row.setAttribute('data-drop-edge', edge);
    if (blocked) {
      row.setAttribute('data-drop-blocked', 'true');
    }

    this.activeDropRow = row;
    this.activeDropChildrenList = null;

    // Always accept the dragover, even for blocked drop targets, so the browser
    // fires a `drop` event instead of running its native cancel animation,
    // which introduces a pause before `dragend`. Blocked targets are rejected
    // in #onDrop, where the drag preview snapback starts immediately.
    event.preventDefault();
  }

  #onDrop(event) {
    if (!this.isDragging || !this.reorderMode) return;

    // Always prevent the default drop action, including for invalid drop targets,
    // so the browser never runs its native return animation, which delays the
    // start of the drag preview snapback.
    event.preventDefault();

    const row = event.target.closest('.node-row');
    if (!row) {
      this.#snapBackAndRemoveDragPreview();
      this.#cleanupDragState();

      return;
    }

    const targetLi = row.closest('li.node');
    if (!targetLi || this.#isBlockedTarget(targetLi)) {
      this.#snapBackAndRemoveDragPreview();
      this.#cleanupDragState();

      return;
    }

    const edge = row.getAttribute('data-drop-edge');
    if (!edge) {
      this.#snapBackAndRemoveDragPreview();
      this.#cleanupDragState();

      return;
    }

    const targetPosition = this.#targetPosition(targetLi, edge);
    const effectiveUris = this.dragEffectiveNodes.map(node =>
      node.getAttribute('data-uri')
    );
    const sourceUris = this.dragSelectionNodes.map(node =>
      node.getAttribute('data-uri')
    );
    const sourceParentUris = this.dragEffectiveNodes.map(node =>
      this.#parentUriForNode(node)
    );
    const sameParentMove =
      sourceParentUris.length > 0 &&
      sourceParentUris.every(uri => uri === targetPosition.parentUri);

    this.treeContainerEl.dispatchEvent(
      new CustomEvent(InfiniteTreeDragDrop.EVENT_DROP_INTENT, {
        bubbles: true,
        detail: {
          sourceNodes: this.dragSelectionNodes.slice(),
          sourceUris,
          effectiveSourceNodes: this.dragEffectiveNodes.slice(),
          effectiveSourceUris: effectiveUris,
          targetNode: targetLi,
          targetUri: targetLi.getAttribute('data-uri'),
          edge,
          targetParentUri: targetPosition.parentUri,
          targetIndex: targetPosition.index,
          sameParentMove,
        },
      })
    );

    // Valid drop, so remove the drag preview immediately with no snapback.
    this.#removeDragPreview();
    this.#cleanupDragState();
  }

  /**
   * Handles the dragend event, which fires after every drag operation ends.
   * For valid drops and invalid drops that fire a drop event, the preview is
   * already removed by the time this runs. For cancelled drags (e.g. ESC key),
   * no drop event fires, so this is the only handler that can clean up.
   */
  #onDragEnd() {
    this.#snapBackAndRemoveDragPreview();
    this.#cleanupDragState();
  }

  #cleanupDragState() {
    document.removeEventListener('dragover', this.dragOverHandler);
    document.removeEventListener('drop', this.documentDropHandler);

    this.dragSelectionNodes.forEach(node =>
      node.classList.remove('is-being-dragged')
    );
    this.dragSelectionNodes = [];
    this.dragEffectiveNodes = [];
    this.isDragging = false;
    this.dragStartPoint = null;
    this.#clearActiveDropIndicators();
  }

  /**
   * Removes the drag preview element immediately, without animation.
   */
  #removeDragPreview() {
    if (this.dragPreviewEl && this.dragPreviewEl.parentNode) {
      this.dragPreviewEl.parentNode.removeChild(this.dragPreviewEl);
    }

    this.dragPreviewEl = null;
  }

  /**
   * Animates the drag preview back to where the drag started, holds
   * briefly, then fades it out before removing it.
   * This mimics the native drag image "snapback" that occurs on a cancelled drop.
   */
  #snapBackAndRemoveDragPreview() {
    const preview = this.dragPreviewEl;
    this.dragPreviewEl = null;
    if (!preview) return;

    if (!this.dragStartPoint) {
      if (preview.parentNode) preview.parentNode.removeChild(preview);
      return;
    }

    const moveDuration = InfiniteTreeDragDrop.DRAG_PREVIEW_SNAPBACK_DURATION;
    const holdDuration = InfiniteTreeDragDrop.DRAG_PREVIEW_SNAPBACK_HOLD;
    const fadeDuration = InfiniteTreeDragDrop.DRAG_PREVIEW_SNAPBACK_FADE;

    preview.style.transition = `left ${moveDuration}ms ease-out, top ${moveDuration}ms ease-out`;

    // Force a reflow so the transition applies from the current position.
    void preview.offsetWidth;

    const offset = InfiniteTreeDragDrop.DRAG_PREVIEW_CURSOR_OFFSET;
    preview.style.left = `${this.dragStartPoint.x + offset}px`;
    preview.style.top = `${this.dragStartPoint.y + offset}px`;

    // Each stage can be triggered by either `transitionend` or its `setTimeout`
    // fallback, so guard against running twice.
    let removePreviewCalled = false;
    let onMoveEndCalled = false;

    preview.addEventListener('transitionend', onMoveEnd, { once: true });

    // Fallback in case transitionend doesn't fire (e.g. no position change).
    setTimeout(onMoveEnd, moveDuration + 50);

    function onMoveEnd() {
      if (onMoveEndCalled) return;
      onMoveEndCalled = true;
      setTimeout(fadeOut, holdDuration);
    }

    function fadeOut() {
      preview.style.transition = `opacity ${fadeDuration}ms ease`;
      void preview.offsetWidth;
      preview.style.opacity = '0';

      preview.addEventListener('transitionend', removePreview, { once: true });
      setTimeout(removePreview, fadeDuration + 50);
    }

    function removePreview() {
      if (removePreviewCalled) return;
      removePreviewCalled = true;
      if (preview.parentNode) preview.parentNode.removeChild(preview);
    }
  }

  #clearActiveDropIndicators() {
    if (this.activeDropRow) {
      this.activeDropRow.removeAttribute('data-drop-edge');
      this.activeDropRow.removeAttribute('data-drop-blocked');
      this.activeDropRow = null;
    }
    if (this.activeDropChildrenList) {
      this.activeDropChildrenList.removeAttribute('data-drop-edge');
      this.activeDropChildrenList.removeAttribute('data-drop-blocked');
      this.activeDropChildrenList = null;
    }
  }

  #buildDragPreview(selectedNodes) {
    const MAX_VISIBLE_ITEMS = 20;
    const containerTemplate = document
      .querySelector('#infinite-tree-drag-preview-template')
      .content.cloneNode(true);
    const containerEl = containerTemplate.querySelector('div');
    const listEl = containerEl.querySelector('ol');
    const itemTemplate = document.querySelector(
      '#infinite-tree-drag-preview-item-template'
    );
    const visibleNodes = selectedNodes.slice(0, MAX_VISIBLE_ITEMS);

    visibleNodes.forEach(selectedNode => {
      const title = selectedNode
        ? (
            selectedNode.querySelector('.record-title')?.textContent || ''
          ).trim()
        : '';
      const itemEl = itemTemplate.content.cloneNode(true).querySelector('li');

      itemEl.textContent = title;
      listEl.appendChild(itemEl);
    });

    const remainingCount = selectedNodes.length - MAX_VISIBLE_ITEMS;

    if (remainingCount > 0) {
      const badgeTemplate = document
        .querySelector('#infinite-tree-drag-preview-count-template')
        .content.cloneNode(true);
      const badgeEl = badgeTemplate.querySelector('div');

      badgeEl.textContent = `+${String(remainingCount)}`;

      containerEl.appendChild(badgeEl);
    }

    document.body.appendChild(containerEl);

    return containerEl;
  }

  #isBlockedTarget(targetLi) {
    return this.dragEffectiveNodes.some(source => {
      if (source === targetLi) return true;

      return source.contains(targetLi);
    });
  }

  #effectiveMoveSet(selectedNodes) {
    return selectedNodes.filter(row => {
      return !selectedNodes.some(other => other !== row && other.contains(row));
    });
  }

  #targetPosition(targetLi, edge) {
    if (edge === 'into') {
      const list = targetLi.querySelector(':scope > .node-children');
      const childCountAttr = targetLi.getAttribute('data-child-count');
      const childCount = childCountAttr
        ? parseInt(childCountAttr, 10)
        : list
          ? list.querySelectorAll(
              ':scope > li.node:not(.js-itree-synthetic-new)'
            ).length
          : 0;

      return {
        parentUri: targetLi.getAttribute('data-uri') || this.rootUri,
        index: childCount,
      };
    }

    const siblings = Array.from(
      targetLi.parentElement.querySelectorAll(
        ':scope > li.node:not(.js-itree-synthetic-new)'
      )
    );
    let index = siblings.indexOf(targetLi);
    const positionAttr = targetLi.getAttribute('data-tree-position');

    if (positionAttr !== null && positionAttr !== '') {
      index = parseInt(positionAttr, 10);
    }

    if (edge === 'bottom') index += 1;

    return {
      parentUri: this.#parentUriForNode(targetLi),
      index,
    };
  }

  #parentUriForNode(node) {
    const parentLi = node.parentElement.closest('li.node');
    if (!parentLi) return this.rootUri;

    return parentLi.getAttribute('data-uri') || this.rootUri;
  }
}
