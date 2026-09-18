(function (exports) {
  class InfiniteTreeIds {
    static #uriPattern = /\/repositories\/([0-9]+)\/([a-z_]+)\/([0-9]+)/;

    /**
     * Explicit edit-mode hierarchy contract per root record type.
     * @type {Record<string, { childType: string, childCollectionPath: string, newFormPath: string }>}
     */
    static #hierarchyMap = {
      resource: {
        childType: 'archival_object',
        childCollectionPath: 'archival_objects',
        newFormPath: 'archival_objects/new',
      },
      digital_object: {
        childType: 'digital_object_component',
        childCollectionPath: 'digital_object_components',
        newFormPath: 'digital_object_components/new',
      },
      classification: {
        childType: 'classification_term',
        childCollectionPath: 'classification_terms',
        newFormPath: 'classification_terms/new',
      },
    };

    static uriToParts(uri) {
      const match = uri.match(this.#uriPattern);
      if (!match) return null;

      const [, , typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');

      return { type, id };
    }

    /**
     * @param {string} rootUri
     * @returns {{ repoId: string, type: string, id: string, childType: string, childCollectionPath: string, newFormPath: string }|null}
     */
    static rootUriToParts(rootUri) {
      const match = rootUri.match(this.#uriPattern);
      if (!match) return null;

      const [, repoId, typePlural, id] = match;
      const type = typePlural.replace(/s$/, '');
      const hierarchy = this.#hierarchyMap[type];

      if (!hierarchy) return null;

      return {
        repoId,
        type,
        id,
        childType: hierarchy.childType,
        childCollectionPath: hierarchy.childCollectionPath,
        newFormPath: hierarchy.newFormPath,
      };
    }

    /**
     * @param {string} childType
     * @returns {{ childType: string, childCollectionPath: string, newFormPath: string }|null}
     */
    static hierarchyForChildType(childType) {
      const entry = Object.values(this.#hierarchyMap).find(
        hierarchy => hierarchy.childType === childType
      );

      return entry || null;
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
