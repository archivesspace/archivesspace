class InfiniteTreeToolbarActions {
  constructor() {
    this.componentEl = document.querySelector('#infinite-tree-component');
    this.treeContainerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    this.toolbarEl = this.componentEl.querySelector('#infinite-tree-toolbar');
    this.rootType = this.componentEl.getAttribute('data-record-type');

    this.#bindEvents();
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
  }

  #onLoadBulkRequested(event) {
    if (this.rootType !== 'resource') return;

    const node = this.#eventNode(event);
    if (!node) return;

    window.file_modal_html = '';
    window.bulkFileSelection();
  }

  #onRdeRequested(event) {
    if (this.rootType !== 'resource' && this.rootType !== 'digital_object') {
      return;
    }

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
}
