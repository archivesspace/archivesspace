class InfiniteTreeCutPaste {
  static EVENT_CUT_PERFORMED = 'infiniteTreeCutPaste:cutPerformed';
  static EVENT_CUT_CLEARED = 'infiniteTreeCutPaste:cutCleared';
  static EVENT_PASTE_INTENT = 'infiniteTreeCutPaste:pasteIntent';

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
    this.cutNodes = [];
    this.cutEffectiveNodes = [];
    this.cutUris = [];

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
      'infiniteTreeToolbar:cutRequested',
      this.#onCutRequested.bind(this)
    );
    this.containerEl.addEventListener(
      'infiniteTreeToolbar:pasteRequested',
      this.#onPasteRequested.bind(this)
    );
    this.containerEl.addEventListener(
      InfiniteTreeReorderActions.EVENT_MOVE_SUCCESS,
      this.#onMoveSuccess.bind(this)
    );
  }

  #onReorderModeChanged(event) {
    this.reorderMode = !!(event.detail && event.detail.enabled);
    if (!this.reorderMode) this.#clearCutState();
  }

  #onSelectionChanged(event) {
    this.explicitSelectionNodes = Array.isArray(event.detail?.selectedNodes)
      ? event.detail.selectedNodes.filter(Boolean)
      : [];
  }

  #onSelectionCleared() {
    this.explicitSelectionNodes = [];
  }

  #onCutRequested() {
    if (!this.reorderMode) return;

    const rootFilteredSelection = this.explicitSelectionNodes.filter(
      node => node && !node.classList.contains('root')
    );
    const fallbackNode = this.#currentSelectedNonRootNode();
    const cutNodes =
      rootFilteredSelection.length > 0
        ? rootFilteredSelection
        : fallbackNode
          ? [fallbackNode]
          : [];

    if (cutNodes.length === 0) return;

    const effectiveNodes = this.#effectiveMoveSet(cutNodes);
    const effectiveUris = effectiveNodes
      .map(node => node.getAttribute('data-uri'))
      .filter(Boolean);

    if (effectiveUris.length === 0) return;

    this.#clearCutClasses();
    this.cutNodes = cutNodes.slice();
    this.cutEffectiveNodes = effectiveNodes.slice();
    this.cutUris = effectiveUris.slice();
    this.cutNodes.forEach(node => node.classList.add('cut'));

    this.#dispatch(InfiniteTreeCutPaste.EVENT_CUT_PERFORMED, {
      cutNodes: this.cutNodes.slice(),
      cutUris: this.cutUris.slice(),
    });
  }

  #onPasteRequested() {
    if (!this.reorderMode) return;
    if (this.cutUris.length === 0 || this.cutEffectiveNodes.length === 0)
      return;

    const targetNode = this.#currentPasteTargetNode();
    if (!targetNode) return;

    const targetUri = targetNode.getAttribute('data-uri');
    if (!targetUri) return;

    const effectivePairs = this.cutEffectiveNodes
      .map((node, idx) => ({
        node,
        uri: this.cutUris[idx] || node.getAttribute('data-uri'),
      }))
      .filter(pair => pair.node && pair.uri && pair.uri !== targetUri);

    if (effectivePairs.length === 0) return;

    const effectiveSourceNodes = effectivePairs.map(pair => pair.node);
    const effectiveSourceUris = effectivePairs.map(pair => pair.uri);
    const sourceParentUris = effectiveSourceNodes.map(node =>
      this.#parentUriForNode(node)
    );
    const sameParentMove =
      sourceParentUris.length > 0 &&
      sourceParentUris.every(uri => uri === targetUri);

    this.#dispatch(InfiniteTreeCutPaste.EVENT_PASTE_INTENT, {
      sourceNodes: this.cutNodes.slice(),
      sourceUris: this.cutNodes
        .map(node => node.getAttribute('data-uri'))
        .filter(Boolean),
      effectiveSourceNodes,
      effectiveSourceUris,
      targetNode,
      targetUri,
      edge: 'into',
      targetParentUri: targetUri,
      targetIndex: this.#childCountForNode(targetNode),
      sameParentMove,
    });
  }

  #onMoveSuccess() {
    if (this.cutUris.length === 0) return;
    this.#clearCutState();
  }

  #clearCutState() {
    const hadCutState = this.cutNodes.length > 0 || this.cutUris.length > 0;

    this.#clearCutClasses();
    this.cutNodes = [];
    this.cutEffectiveNodes = [];
    this.cutUris = [];

    if (hadCutState) {
      this.#dispatch(InfiniteTreeCutPaste.EVENT_CUT_CLEARED, {});
    }
  }

  #clearCutClasses() {
    this.containerEl.querySelectorAll('li.node.cut').forEach(node => {
      node.classList.remove('cut');
    });
  }

  #currentSelectedNonRootNode() {
    const node = this.containerEl.querySelector('li.node.selected');
    if (!node || node.classList.contains('root')) return null;
    return node;
  }

  /**
   * Resolve the paste destination from the current `.selected` row, including root,
   * when it is not `.cut`.
   * @returns {HTMLElement|null}
   */
  #currentPasteTargetNode() {
    const node = this.containerEl.querySelector('li.node.selected:not(.cut)');
    return node || null;
  }

  #childCountForNode(node) {
    const childCountAttr = node.getAttribute('data-child-count');
    const parsed = parseInt(childCountAttr || '', 10);
    if (Number.isFinite(parsed)) return parsed;

    const list = node.querySelector(':scope > .node-children');
    if (!list) return 0;

    return list.querySelectorAll(
      ':scope > li.node:not(.js-itree-synthetic-new)'
    ).length;
  }

  #parentUriForNode(node) {
    const parentLi = node.parentElement.closest('li.node');
    if (!parentLi) return this.rootUri;
    return parentLi.getAttribute('data-uri') || this.rootUri;
  }

  #effectiveMoveSet(selectedNodes) {
    return selectedNodes.filter(row => {
      return !selectedNodes.some(other => other !== row && other.contains(row));
    });
  }

  #dispatch(type, detail) {
    this.containerEl.dispatchEvent(
      new CustomEvent(type, {
        bubbles: true,
        detail,
      })
    );
  }
}
