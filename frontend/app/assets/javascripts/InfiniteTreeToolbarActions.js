//= require InfiniteTreeFetch
//= require InfiniteTreeIds

class InfiniteTreeToolbarActions {
  constructor() {
    this.componentEl = document.querySelector('#infinite-tree-component');
    this.treeContainerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    this.toolbarEl = this.componentEl.querySelector('#infinite-tree-toolbar');
    this.recordPaneEl = this.componentEl.querySelector(
      '#infinite-tree-record-pane'
    );
    this.fetch = new InfiniteTreeFetch(this.componentEl.dataset.rootUri);
    this.cutNodeUris = [];
    this.pastePlacementMode = 'append_as_child';
    this.reorderModeEnabled = false;

    this.#bindEvents();
    this.#emitCutStateChanged(false);
  }

  #bindEvents() {
    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:loadBulkRequested',
      this.#onLoadBulkRequested.bind(this)
    );

    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:rdeRequested',
      this.#onRdeRequested.bind(this)
    );

    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:cutRequested',
      this.#onCutRequested.bind(this)
    );

    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:pasteRequested',
      this.#onPasteRequested.bind(this)
    );

    this.treeContainerEl.addEventListener(
      'infiniteTreeToolbar:reorderModeChanged',
      this.#onReorderModeChanged.bind(this)
    );
  }

  #onLoadBulkRequested(event) {
    const node = this.#eventNode(event);
    if (!node) return;

    window.file_modal_html = '';
    window.bulkFileSelection();
  }

  #onRdeRequested(event) {
    const node = this.#eventNode(event);
    if (!node || !node.getAttribute('data-uri')) return;

    const $ = window.jQuery;
    const $node = $(node);
    const buttonEl = this.toolbarEl.querySelector('.js-itree-toolbar-rde');
    const $button = $(buttonEl);

    $(document).triggerHandler('rdeshow.aspace', [$node, $button]);
  }

  #eventNode(event) {
    return event && event.detail ? event.detail.node : null;
  }

  #onReorderModeChanged(event) {
    this.reorderModeEnabled = !!(event.detail && event.detail.enabled);

    if (!this.reorderModeEnabled) {
      this.#clearCutState();
    }
  }

  #onCutRequested() {
    if (!this.reorderModeEnabled) return;

    const selectedNode = this.#selectedNode();

    if (!selectedNode || selectedNode.classList.contains('root')) {
      this.#clearCutState();

      return;
    }

    const uri = selectedNode.getAttribute('data-uri');

    this.#clearCutMarkers();
    selectedNode.classList.add('cut');
    this.cutNodeUris = [uri];
    this.#emitCutStateChanged(true);
  }

  async #onPasteRequested() {
    if (!this.reorderModeEnabled) return;
    if (this.cutNodeUris.length === 0) return;

    const destinationNode = this.#selectedNode();
    const destinationUri = destinationNode.getAttribute('data-uri');
    const rowsToPaste = this.cutNodeUris.filter(uri => uri !== destinationUri);
    if (rowsToPaste.length === 0) return;
    const primaryMovedUri = rowsToPaste[0];

    try {
      const placement = await this.#resolvePastePlacement({
        destinationNode,
        cutNodes: rowsToPaste,
        placementMode: this.pastePlacementMode,
      });

      if (!placement) return;

      await this.fetch.acceptChildren(
        placement.targetUri,
        rowsToPaste,
        placement.index
      );

      this.#clearCutState();
      this.#redisplayAndShow(destinationUri, primaryMovedUri, rowsToPaste);
    } catch (error) {
      this.#showMoveError(error);
    }
  }

  async #resolvePastePlacement({ destinationNode, cutNodes, placementMode }) {
    if (!destinationNode || !Array.isArray(cutNodes) || cutNodes.length === 0)
      return null;

    if (placementMode !== 'append_as_child') {
      throw new Error(`Unsupported paste placement mode: ${placementMode}`);
    }

    const targetUri = destinationNode.getAttribute('data-uri');
    if (!targetUri) return null;

    let childCount = this.#readNodeChildCount(destinationNode);

    if (childCount === null) {
      childCount = await this.#fetchChildCount(targetUri);
    }

    return {
      targetUri,
      index: childCount,
    };
  }

  #readNodeChildCount(node) {
    const value = node.getAttribute('data-child-count');

    if (value === null || value === '') return null;

    const parsed = Number(value);

    return Number.isNaN(parsed) ? null : parsed;
  }

  async #fetchChildCount(uri) {
    const data = await this.fetch.nodeByUri(uri);

    if (!data || typeof data.child_count !== 'number') {
      throw new Error('Unable to resolve destination child count');
    }

    return data.child_count;
  }

  #selectedNode() {
    return this.treeContainerEl.querySelector('li.node.selected');
  }

  #clearCutState() {
    this.cutNodeUris = [];
    this.#clearCutMarkers();
    this.#emitCutStateChanged(false);
  }

  #clearCutMarkers() {
    this.treeContainerEl.querySelectorAll('li.node.cut').forEach(node => {
      node.classList.remove('cut');
    });
  }

  #emitCutStateChanged(hasCut) {
    this.treeContainerEl.dispatchEvent(
      new CustomEvent('infiniteTreeToolbar:cutStateChanged', {
        bubbles: true,
        detail: {
          hasCut: !!hasCut,
        },
      })
    );
  }

  #redisplayAndShow(uri, ensureVisibleUri = null, movedUris = []) {
    const targetUri = ensureVisibleUri || uri;
    const highlightUris = Array.isArray(movedUris)
      ? movedUris.slice()
      : ensureVisibleUri
        ? [ensureVisibleUri]
        : [];

    this.treeContainerEl.dispatchEvent(
      new CustomEvent('infiniteTreeRouter:redisplayAndShow', {
        detail: {
          targetHash: InfiniteTreeIds.treeLinkUrl(targetUri),
          options: {
            preserveScroll: false,
            scrollToNode: true,
            ensureVisibleUri,
            selectedUri: uri,
            highlightUris,
          },
        },
      })
    );
  }

  #showMoveError(error) {
    const message =
      error && error.message
        ? error.message
        : 'Unable to paste the selected node.';
    const title = 'Unable to move node';

    if (window.AS && typeof window.AS.openQuickModal === 'function') {
      window.AS.openQuickModal(title, message);
    } else {
      window.alert(message);
    }

    console.error('InfiniteTree paste failed:', error);
  }
}
