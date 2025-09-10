//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRouter2 {
    constructor({ rootUri }) {
      this.rootUri = rootUri;
      this.currentHash = window.location.hash;
      this.inflight = null;
      this.treeContainer = document.querySelector('#infinite-tree-container');

      this.init();
    }

    init() {
      let targetHash;

      if (this.currentHash === '') {
        targetHash = InfiniteTreeIds.uriToLocationHash(this.rootUri);
        this.setHash(targetHash);
      } else {
        targetHash = this.currentHash;
      }

      this.treeContainer.dispatchEvent(
        new CustomEvent('infiniteTreeRouter:hashchange', {
          detail: { targetHash },
        })
      );
    }

    setHash(hash) {
      window.location.hash = this.#normalizeHash(hash);

      this.currentHash = window.location.hash;
    }

    /**
     * Normalizes hash by removing # prefix if present
     * @param {string} hash - The hash string to normalize
     * @returns {string} Normalized hash without #
     * @private
     */
    #normalizeHash(hash) {
      return hash.replace(/^#/, '');
    }
  }

  exports.InfiniteTreeRouter2 = InfiniteTreeRouter2;
})(window);
