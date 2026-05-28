class InfiniteTreeMove {
  static EVENT_MOVE_INTENT = 'infiniteTreeMove:moveIntent';

  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.containerEl = this.componentEl.querySelector('#infinite-tree-container');
    if (!this.containerEl) return;

    this.rootUri = this.componentEl.getAttribute('data-root-uri') || '';
    this.reorderMode = false;

    this.#bindEvents();
  }

  #bindEvents() {
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:moveOptionSelected',
      this.#onMoveOptionSelected.bind(this)
    );
  }

  #onReorderModeChanged(event) {
    this.reorderMode = !!(event.detail && event.detail.enabled);
  }

  #onMoveOptionSelected(event) {
    if (!this.reorderMode) return;

    const detail = event.detail || {};
    const action = detail.action || '';
    if (!action) return;

    const sourceNode = this.#sourceNonRootNode();
    if (!sourceNode) return;

    this.#dispatchMoveIntent(action, sourceNode, detail.targetNodeId || null);
  }

  /**
   * @param {string} action
   * @param {HTMLElement} sourceNode
   * @param {string|null} targetNodeId
   */
  #dispatchMoveIntent(action, sourceNode, targetNodeId) {
    const sourceUri = sourceNode.getAttribute('data-uri');
    if (!sourceUri) return;

    const sourceParentNode = sourceNode.parentElement
      ? sourceNode.parentElement.closest('li.node')
      : null;
    const sourceParentUri = sourceParentNode
      ? sourceParentNode.getAttribute('data-uri') || this.rootUri
      : this.rootUri;

    let targetNode = null;
    let targetUri = null;
    let targetParentUri = null;
    let targetIndex = null;
    let edge = null;

    if (action === 'up-level') {
      const parentNode = sourceParentNode;
      const grandparentNode = parentNode
        ? parentNode.parentElement.closest('li.node')
        : null;
      if (!grandparentNode) return;

      targetNode = grandparentNode;
      targetUri = grandparentNode.getAttribute('data-uri') || this.rootUri;
      targetParentUri = targetUri;
      targetIndex = this.#childCountForNode(grandparentNode);
      edge = 'into';
    } else if (action === 'up') {
      const previousSibling = this.#previousNodeSibling(sourceNode);
      if (!previousSibling) return;

      targetNode = previousSibling;
      targetUri = previousSibling.getAttribute('data-uri') || null;
      targetParentUri = sourceParentUri;
      targetIndex = this.#positionForNode(previousSibling);
      edge = 'top';
    } else if (action === 'down') {
      const nextSibling = this.#nextNodeSibling(sourceNode);
      if (!nextSibling) return;

      targetNode = nextSibling;
      targetUri = nextSibling.getAttribute('data-uri') || null;
      targetParentUri = sourceParentUri;
      const nextPosition = this.#positionForNode(nextSibling);
      targetIndex = Number.isFinite(nextPosition) ? nextPosition + 1 : null;
      edge = 'bottom';
    } else if (action === 'down-into') {
      if (!targetNodeId) return;

      const siblingNode = this.containerEl.querySelector(
        `li.node#${CSS.escape(targetNodeId)}`
      );
      if (!siblingNode) return;

      targetNode = siblingNode;
      targetUri = siblingNode.getAttribute('data-uri') || null;
      targetParentUri = targetUri;
      targetIndex = this.#childCountForNode(siblingNode);
      edge = 'into';
    } else {
      return;
    }

    if (!targetParentUri || !Number.isFinite(targetIndex)) return;

    const sameParentMove = sourceParentUri === targetParentUri;
    this.containerEl.dispatchEvent(
      new CustomEvent(InfiniteTreeMove.EVENT_MOVE_INTENT, {
        bubbles: true,
        detail: {
          sourceNodes: [sourceNode],
          sourceUris: [sourceUri],
          effectiveSourceNodes: [sourceNode],
          effectiveSourceUris: [sourceUri],
          targetNode,
          targetUri,
          edge,
          targetParentUri,
          targetIndex,
          sameParentMove,
        },
      })
    );
  }

  /**
   * Resolve the row to move. Move always applies to the current `.selected` node.
   * @returns {HTMLElement|null}
   */
  #sourceNonRootNode() {
    const selected = this.containerEl.querySelector('li.node.selected');
    if (!selected || selected.classList.contains('root')) return null;
    return selected;
  }

  #childCountForNode(node) {
    const childCountAttr = node.getAttribute('data-child-count');
    const parsed = parseInt(childCountAttr || '', 10);
    if (Number.isFinite(parsed)) return parsed;

    const list = node.querySelector(':scope > .node-children');
    if (!list) return 0;

    return list.querySelectorAll(':scope > li.node:not(.js-itree-synthetic-new)')
      .length;
  }

  #positionForNode(node) {
    const positionAttr = node.getAttribute('data-tree-position');
    const parsed = parseInt(positionAttr || '', 10);
    if (Number.isFinite(parsed)) return parsed;

    if (!node.parentElement) return null;
    const siblings = Array.from(
      node.parentElement.querySelectorAll(
        ':scope > li.node:not(.js-itree-synthetic-new)'
      )
    );
    const index = siblings.indexOf(node);

    return index === -1 ? null : index;
  }

  #previousNodeSibling(node) {
    let previous = node.previousElementSibling;
    while (previous) {
      if (
        previous.matches('li.node') &&
        !previous.classList.contains('js-itree-synthetic-new')
      ) {
        return previous;
      }
      previous = previous.previousElementSibling;
    }
    return null;
  }

  #nextNodeSibling(node) {
    let next = node.nextElementSibling;
    while (next) {
      if (
        next.matches('li.node') &&
        !next.classList.contains('js-itree-synthetic-new')
      ) {
        return next;
      }
      next = next.nextElementSibling;
    }
    return null;
  }
}
