class InfiniteTreeDragDrop {
  static EVENT_DROP_INTENT = 'infiniteTreeDragDrop:dropIntent';

  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.containerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    if (!this.containerEl) return;

    this.rootUri = this.componentEl.getAttribute('data-root-uri') || '';
    this.reorderMode = false;

    this.explicitSelectionNodes = [];
    this.dragSelectionNodes = [];
    this.dragEffectiveNodes = [];
    this.dragPreviewEl = null;
    this.activeDropRow = null;
    this.activeDropChildrenList = null;
    this.dragging = false;
    this.observer = null;

    this.#bindEvents();
  }

  #bindEvents() {
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );
    this.containerEl.addEventListener(
      InfiniteTreeSelection.EVENT_CHANGED,
      this.#onSelectionChanged.bind(this)
    );
    this.containerEl.addEventListener(
      InfiniteTreeSelection.EVENT_CLEARED,
      this.#onSelectionCleared.bind(this)
    );
    this.containerEl.addEventListener(
      'dragstart',
      this.#onDragStart.bind(this)
    );
    this.containerEl.addEventListener('dragover', this.#onDragOver.bind(this));
    this.containerEl.addEventListener('drop', this.#onDrop.bind(this));
    this.containerEl.addEventListener('dragend', this.#onDragEnd.bind(this));
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
    const rows = this.containerEl.querySelectorAll(
      'li.node:not(.root):not(.js-itree-synthetic-new) > .node-row'
    );
    rows.forEach(row => {
      row.setAttribute('draggable', 'true');
      row.setAttribute('title', 'Drag to reorder');
      row.setAttribute('aria-label', 'Drag to reorder');
    });
  }

  #disableDraggables() {
    this.containerEl.querySelectorAll('.node-row[draggable]').forEach(row => {
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
    this.observer.observe(this.containerEl, { childList: true, subtree: true });
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
    this.dragging = true;

    this.dragSelectionNodes.forEach(node =>
      node.classList.add('is-being-dragged')
    );
    this.dragPreviewEl = this.#buildDragPreview(this.dragSelectionNodes);

    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', 'infinite-tree-drag');
      if (this.dragPreviewEl) {
        event.dataTransfer.setDragImage(this.dragPreviewEl, 12, 12);
      }
    }
  }

  #onDragOver(event) {
    if (!this.dragging || !this.reorderMode) return;
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

    if (!blocked) {
      event.preventDefault();
    }
  }

  #onDrop(event) {
    if (!this.dragging || !this.reorderMode) return;

    const row = event.target.closest('.node-row');
    if (!row) {
      this.#cleanupDragState();
      return;
    }

    const targetLi = row.closest('li.node');
    if (!targetLi || this.#isBlockedTarget(targetLi)) {
      this.#cleanupDragState();
      return;
    }

    const edge = row.getAttribute('data-drop-edge');
    if (!edge) {
      this.#cleanupDragState();
      return;
    }

    event.preventDefault();

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

    this.containerEl.dispatchEvent(
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

    this.#cleanupDragState();
  }

  #onDragEnd() {
    this.#cleanupDragState();
  }

  #cleanupDragState() {
    this.dragSelectionNodes.forEach(node =>
      node.classList.remove('is-being-dragged')
    );
    this.dragSelectionNodes = [];
    this.dragEffectiveNodes = [];
    this.dragging = false;

    this.#clearActiveDropIndicators();

    if (this.dragPreviewEl && this.dragPreviewEl.parentNode) {
      this.dragPreviewEl.parentNode.removeChild(this.dragPreviewEl);
    }
    this.dragPreviewEl = null;
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
    const node = document.createElement('div');
    node.className = 'infinite-tree-drag-preview';
    const first = selectedNodes[0];
    const title = first
      ? (first.querySelector('.record-title')?.textContent || '').trim()
      : '';
    const extraCount = Math.max(selectedNodes.length - 1, 0);

    node.innerHTML =
      '<div class="infinite-tree-drag-preview__row">' +
      '<span class="infinite-tree-drag-preview__title"></span>' +
      '<span class="infinite-tree-drag-preview__count"></span>' +
      '</div>';
    node.querySelector('.infinite-tree-drag-preview__title').textContent =
      title;

    const badge = node.querySelector('.infinite-tree-drag-preview__count');
    if (extraCount > 0) {
      badge.textContent = '+' + String(extraCount);
    } else {
      badge.hidden = true;
    }

    document.body.appendChild(node);
    return node;
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
      const childCount = list
        ? list.querySelectorAll(':scope > li.node:not(.js-itree-synthetic-new)')
            .length
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
