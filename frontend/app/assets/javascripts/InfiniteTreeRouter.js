//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRouter {
    constructor({ rootUri }) {
      this.rootUri = rootUri;
      this.currentHash = window.location.hash;
      this.inflight = null;
      this.treeContainer = document.querySelector('#infinite-tree-container');

      this.treeContainer.addEventListener('infiniteTree:titleClick', e => {
        const { node } = e.detail;
        this.setHash(InfiniteTreeIds.uriToLocationHash(node.dataset.uri));
        this.dispatchNodeSelect(window.location.hash);
      });

      this.init();
    }

    init() {
      if (this.currentHash === '') {
        const fragment = InfiniteTreeIds.treeLinkUrl(this.rootUri);

        this.setHash(fragment);

        this.dispatchNodeSelect(window.location.hash);
      } else {
        this.dispatchNodeSelect(this.currentHash);
      }
    }

    dispatchNodeSelect(hash) {
      const fragment = hash && hash.startsWith('#') ? hash : `#${hash}`;
      this.treeContainer.dispatchEvent(
        new CustomEvent('infiniteTreeRouter:nodeSelect', {
          detail: {
            targetHash: fragment,
          },
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

  exports.InfiniteTreeRouter = InfiniteTreeRouter;
})(window);
