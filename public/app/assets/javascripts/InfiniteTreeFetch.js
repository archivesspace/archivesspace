(function (exports) {
  class InfiniteTreeFetch {
    /**
     * @constructor
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     */
    constructor(appUrlPrefix, resourceUri) {
      this.appUrlPrefix = appUrlPrefix;
      this.resourceUri = resourceUri;
      this.repoId = resourceUri.split('/')[2];
      // this.baseUri = `/resources/${this.resourceId}/tree`;
      this.baseUri = `${this.resourceUri}/tree`;
      this.rootUri = `${this.baseUri}/root`;
      this.nodeUri = `${this.baseUri}/node`;
      this.batchUri = `${this.baseUri}/waypoint`; // TODO: rename endpoint to /batch
    }

    /**
     * Fetch the root data
     * @returns {Object} - Root data object returned from the server
     */
    async root() {
      try {
        const response = await fetch(this.appUrlPrefix + this.rootUri);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetch the tree of the node with the given id
     * @param {number} nodeId - ID of the node, ie: 18028
     * @returns {Object} - Node object as returned from the server
     */
    async node(nodeId) {
      const query = new URLSearchParams();

      query.append(
        'node',
        `/repositories/${this.repoId}/archival_objects/${nodeId}`
      );

      try {
        const response = await fetch(`${this.nodeUri}?${query}`);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetch a batch of the given node's children
     * @param {Object} params - Object of params for the ajax call with the signature:
     * @param {string} params.node - Node URL param in the form of '' or
     * '/repositories/X/archival_objects/Y'
     * @param {number} params.offset - Offset URL param
     * @returns {array} - Array of batch objects as returned from the server
     */
    async batch(params) {
      const query = new URLSearchParams();

      for (const key in params) {
        query.append(key, params[key]);
      }

      try {
        const response = await fetch(`${this.batchUri}?${query}`);
        const batch = await response.json();

        return batch;
      } catch (err) {
        console.error('Error fetching batch:', err);
        return null;
      }
    }
  }

  exports.InfiniteTreeFetch = InfiniteTreeFetch;
})(window);
