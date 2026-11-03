(function (exports) {
  /**
   * Public-app helpers for translating between record URIs, tree node HTML
   * ids, and the hierarchy each tree root type owns. Modeled on the staff
   * `InfiniteTreeIds` but scoped to what the PUI needs; the two codebases are
   * intentionally separate.
   */
  class InfiniteTreeIds {
    static #uriPattern = /^\/repositories\/([0-9]+)\/([a-z_]+)\/([0-9]+)$/;

    /**
     * Root record type => child record type
     * @type {Object<string, string>}
     */
    static #childTypes = {
      resource: 'archival_object',
      digital_object: 'digital_object_component',
      classification: 'classification_term',
    };

    /**
     * @param {string} uri - eg '/repositories/2/archival_objects/18028'
     * @returns {{repoId: string, type: string, id: string}|null} - eg
     * {repoId: '2', type: 'archival_object', id: '18028'}
     */
    static parseUri(uri) {
      const match = typeof uri === 'string' && uri.match(this.#uriPattern);

      if (!match) return null;

      const [, repoId, typePlural, id] = match;

      return { repoId, type: typePlural.replace(/s$/, ''), id };
    }

    /**
     * @param {string} rootType - eg 'resource'
     * @returns {string|null} - eg 'archival_object'
     */
    static childTypeFor(rootType) {
      return this.#childTypes[rootType] || null;
    }

    /**
     * @param {string} type - A record type, eg 'classification'
     * @returns {boolean} - True if the type is a tree root type
     */
    static isRootType(type) {
      return Object.prototype.hasOwnProperty.call(this.#childTypes, type);
    }

    /**
     * @param {string} uri - eg '/repositories/2/classification_terms/5'
     * @returns {string} - The node's HTML id, eg 'classification_term_5'
     */
    static uriToElementId(uri) {
      const parts = this.parseUri(uri);

      return `${parts.type}_${parts.id}`;
    }

    /**
     * Build a child record URI from a root URI and a child record id
     * @param {string} rootUri - eg '/repositories/2/digital_objects/3'
     * @param {string|number} id - Child record id, eg 7
     * @returns {string} - eg '/repositories/2/digital_object_components/7'
     */
    static childUri(rootUri, id) {
      const root = this.parseUri(rootUri);

      return `/repositories/${root.repoId}/${this.childTypeFor(root.type)}s/${id}`;
    }

    /**
     * Convert a node HTML id back into a parent reference for the batch
     * endpoint: '' for the tree root, otherwise the node's record URI
     * @param {string} elementId - eg 'classification_term_5' or 'resource_1'
     * @param {string} repoId - The repository id, eg '2'
     * @returns {string} - eg '/repositories/2/classification_terms/5' or ''
     */
    static elementIdToParentRef(elementId, repoId) {
      const split = elementId.lastIndexOf('_');
      const type = elementId.slice(0, split);
      const id = elementId.slice(split + 1);

      if (this.isRootType(type)) return '';

      return `/repositories/${repoId}/${type}s/${id}`;
    }

    /**
     * Parse a collection-organization location hash
     * @param {string} hash - eg '#tree::archival_object_18028', with or
     * without the leading '#'
     * @returns {{type: string, id: string}|null}
     */
    static parseLocationHash(hash) {
      const match = (hash || '').match(/^#?tree::([a-z_]+)_([0-9]+)$/);

      if (!match) return null;

      return { type: match[1], id: match[2] };
    }

    /**
     * @param {string} uri - Record URI
     * @returns {string} - eg '#tree::archival_object_18028'
     */
    static uriToLocationHash(uri) {
      return `#tree::${this.uriToElementId(uri)}`;
    }
  }

  exports.InfiniteTreeIds = InfiniteTreeIds;
})(window);
