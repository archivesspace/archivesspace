(function (exports) {
  class InfiniteTreeIds {
    static #uriPattern = /\/repositories\/([0-9]+)\/([a-z_]+)\/([0-9]+)/;

    /**
     * @returns {Record<string, { childType: string }>}
     */
    static #hierarchyConfig() {
      const config = exports.InfiniteTreeHierarchyConfig;

      if (!config || typeof config !== 'object') {
        throw new Error(
          'InfiniteTreeHierarchyConfig is missing. It must be assigned before ' +
            'InfiniteTree modules initialize.'
        );
      }

      return config;
    }

    /**
     * @param {string} childType
     * @returns {{ childType: string, childCollectionPath: string, newFormPath: string }}
     */
    static #pathsForChildType(childType) {
      const childCollectionPath = `${childType}s`;

      return {
        childType,
        childCollectionPath,
        newFormPath: `${childCollectionPath}/new`,
      };
    }

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
      const entry = this.#hierarchyConfig()[type];

      if (!entry || !entry.childType) return null;

      const paths = this.#pathsForChildType(entry.childType);

      return {
        repoId,
        type,
        id,
        childType: paths.childType,
        childCollectionPath: paths.childCollectionPath,
        newFormPath: paths.newFormPath,
      };
    }

    /**
     * @param {string} childType
     * @returns {{ childType: string, childCollectionPath: string, newFormPath: string }|null}
     */
    static hierarchyForChildType(childType) {
      if (!childType) return null;

      const known = Object.values(this.#hierarchyConfig()).some(
        entry => entry && entry.childType === childType
      );

      if (!known) return null;

      return this.#pathsForChildType(childType);
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
     * @param {string} hash the URI fragment with or without a '#' prefix
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

      return AS.app_prefix(`/${parts.type}s/${parts.id}`);
    }
  }

  exports.InfiniteTreeIds = InfiniteTreeIds;
})(window);
