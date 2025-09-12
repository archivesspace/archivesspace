(function (exports) {
  class InfiniteTreeIds {
    static #uriPattern = /\/repositories\/([0-9]+)\/([a-z_]+)\/([0-9]+)/;

    static #childTypeMap = {
      resource: 'archival_object',
      digital_object: 'digital_object_component',
      classification: 'classification_term',
    };

    static uriToParts(uri) {
      const match = uri.match(this.#uriPattern);
      if (!match) return null;

      const [, , typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');

      return { type, id };
    }

    static rootUriToParts(rootUri) {
      const match = rootUri.match(this.#uriPattern);
      if (!match) return null;

      const [, repoId, typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');
      const childType = this.#childTypeMap[type];

      return { repoId, type, id, childType };
    }

    static uriToTreeId(uri) {
      const parts = this.uriToParts(uri);

      return `${parts.type}_${parts.id}`;
    }

    static parseTreeId(treeId) {
      const match = treeId.match(/^([a-z_]+)_([0-9]+)$/);
      if (!match) return null;

      const [, type, id] = match;

      return { type, id };
    }

    static uriToLocationHash(uri) {
      return `tree::${this.uriToTreeId(uri)}`;
    }

    /**
     *
     * @param {string} hash the URI fragment hash, with or without # prefix
     * @returns {string} the HTML id of the node
     */
    static locationHashToHtmlId(hash) {
      return hash.replace(/^#?tree::/, '');
    }

    static treeLinkUrl(uri) {
      return `#${this.uriToLocationHash(uri)}`;
    }

    static backendUriToFrontendUri(uri) {
      return AS.app_prefix(uri.replace(/\/repositories\/[0-9]+\//, ''));
    }

    static locationHashToFrontendUri(hash) {
      const treeId = hash.replace(/^#?tree::/, '');
      const parts = this.parseTreeId(treeId);

      return `/${parts.type}s/${parts.id}`;
    }
  }

  exports.InfiniteTreeIds = InfiniteTreeIds;
})(window);
