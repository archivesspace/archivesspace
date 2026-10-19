(function (exports) {
  /**
   * Shares the current record between InfiniteRecords and InfiniteTree on the
   * collection organization page
   */
  class InfiniteCoordinator {
    constructor() {
      this.currentRecordUri = null;
      this.tree = null;
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

    /**
     * Called by InfiniteTree so current-node updates are scoped to that tree
     * @param {InfiniteTree} tree - The tree instance
     */
    registerTree(tree) {
      this.tree = tree;
    }

    /**
     * Marks the tree node for the current record as current
     */
    updateCurrentTreeNode() {
      if (this.tree) {
        this.tree.markCurrent(this.currentRecordUri);
      }
    }
  }

  exports.InfiniteCoordinator = InfiniteCoordinator;
})(window);
