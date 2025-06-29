(function (exports) {
  class InfiniteCoordinator {
    constructor() {
      this.currentRecordUri = null;
    }

    /**
     * @param {string} uri - eg '/repositories/2/archival_objects/4549'
     */
    set currentRecord(uri) {
      this.currentRecordUri = uri;
    }

    get currentRecord() {
      return this.currentRecordUri;
    }

    updateCurrentTreeNode() {
      const _new = document.querySelector(
        `#infinite-tree-container .node[data-uri="${this.currentRecordUri}"]`
      );
      const old = document.querySelector(
        '#infinite-tree-container .node.current'
      );

      if (old) {
        old.classList.remove('current');
      }

      if (_new) {
        _new.classList.add('current');
      }
    }
  }

  exports.InfiniteCoordinator = InfiniteCoordinator;
})(window);
