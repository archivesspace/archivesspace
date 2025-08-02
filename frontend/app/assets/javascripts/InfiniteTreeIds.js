(function (exports) {
  class InfiniteTreeIds {
    static #uriPattern = /\/repositories\/([0-9]+)\/([a-z_]+)\/([0-9]+)/;

    static #childTypeMap = {
      resource: 'archival_object',
      digital_object: 'digital_object_component',
      classification: 'classification_term',
    };

    static uriToTreeId(uri) {
      const parts = this.uriToParts(uri);

      return `${parts.type}_${parts.id}`;
    }

    static uriToLocationHash(uri) {
      return `tree::${this.uriToTreeId(uri)}`;
    }

    /**
     *
     * @param {string} hash the URI fragment returned from window.location.hash
     * @returns {string} the HTML id of the node
     */
    static locationHashToHtmlId(hash) {
      return hash.replace('#tree::', '');
    }

    static rootUriToParts(rootUri) {
      const match = rootUri.match(this.#uriPattern);
      if (!match) return null;

      const [, repoId, typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');
      const childType = this.#childTypeMap[type];

      return { repoId, type, id, childType };
    }

    static uriToParts(uri) {
      const match = uri.match(this.#uriPattern);
      if (!match) return null;

      const [, , typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');

      return { type, id };
    }

    static backendUriToFrontendUri(uri) {
      return AS.app_prefix(uri.replace(/\/repositories\/[0-9]+\//, ''));
    }

    static locationHashToFrontendUri(hash) {
      const treeId = hash.replace('tree::', '');
      const parts = this.parseTreeId(treeId);

      return `/${parts.type}s/${parts.id}`;
    }

    static parseTreeId(treeId) {
      const match = treeId.match(/([a-z_]+)([0-9]+)/);
      if (!match) return null;

      const [, rowType, rowId] = match;

      return { type: rowType.replace(/_$/, ''), id: rowId };
    }

    static treeLinkUrl(uri) {
      return `#${this.uriToLocationHash(uri)}`;
    }
  }

  exports.InfiniteTreeIds = InfiniteTreeIds;
})(window);
