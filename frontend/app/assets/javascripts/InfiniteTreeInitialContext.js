//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeInitialContext {
    /**
     * @constructor
     * @param {string} rootUri - Backend URI of the root record, e.g. "/repositories/2/resources/123"
     */
    constructor(rootUri) {
      this.rootUri = rootUri;
      this.locationHash = this.#resolveInitialHash();
      this.isRoot = this.locationHash === InfiniteTreeIds.treeLinkUrl(rootUri);
    }

    /**
     * @returns {Object} context - Initial context for the tree
     * @returns {boolean} context.isRoot - Whether the initial selection is the root
     * @returns {string} [context.locationHash] - The document's URI fragment after page load
     * @returns {string} context.rootUri - Backend URI of the root record
     */
    get context() {
      if (this.isRoot) {
        return { isRoot: true, rootUri: this.rootUri };
      } else {
        return {
          isRoot: false,
          locationHash: this.locationHash,
          rootUri: this.rootUri,
        };
      }
    }

    /**
     * Ensures a canonical location hash exists when the hash is empty (root).
     *
     * @returns {string} - The document's location hash after processing
     */
    #resolveInitialHash() {
      const currentHash = window.location.hash;

      if (currentHash === '') {
        window.location.hash = InfiniteTreeIds.uriToLocationHash(this.rootUri);

        return window.location.hash;
      }

      return currentHash;
    }
  }

  exports.InfiniteTreeInitialContext = InfiniteTreeInitialContext;
})(window);
