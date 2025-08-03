//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeFetch {
    /**
     * @constructor
     * @param {string} rootRecordUri - The backend URI of the root record, e.g. "/repositories/1/resources/3"
     */
    constructor(rootRecordUri) {
      const baseUrl =
        InfiniteTreeIds.backendUriToFrontendUri(rootRecordUri) + '/tree';
      const rootParts = InfiniteTreeIds.rootUriToParts(rootRecordUri);

      this.rootUrl = baseUrl + '/root';
      this.nodeUrl = baseUrl + '/node';
      this.batchUrl = baseUrl + '/waypoint'; // TODO: rename endpoint to /batch
      this.ancestorsUrl = baseUrl + '/node_from_root'; // TODO: rename endpoint to /ancestors
      this.nodeSearchParamsBase =
        '/repositories/' + rootParts.repoId + '/' + rootParts.childType + 's/';
    }

    /**
     * Fetches either the root or a node with the given id
     * @param {number|null} [id] - ID of the node or null for the root node
     * @returns {Object} - Root or node object returned from the server
     */
    async node(id = null) {
      if (id === null) {
        return this.#root();
      } else {
        return this.#node(id);
      }
    }

    /**
     * Private method to fetch the root
     * @returns {Object} - Root object returned from the server
     */
    async #root() {
      try {
        const response = await fetch(this.rootUrl);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Private method to fetch the node with the given id
     * @param {number} id - ID of the node, ie: 18028
     * @returns {Object} - Node object as returned from the server
     */
    async #node(id) {
      const query = new URLSearchParams({
        node: this.nodeSearchParamsBase + id,
      });

      try {
        const response = await fetch(this.nodeUrl + '?' + query);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetches a batch of the given parent's children
     * @param {string} parentRef - The parent reference for the endpoint; either '' for root,
     * or the backend URI of the parent node, ie: '/repositories/:rid/archival_objects/:id'
     * @param {number} offset - The parent's batch offset to fetch, 0-indexed
     * @returns {array} - Array of node objects as returned from the server
     */
    async batch(parentRef, offset) {
      const query = new URLSearchParams({
        node: parentRef,
        offset,
      });

      try {
        const response = await fetch(this.batchUrl + '?' + query);

        return await response.json();
      } catch (err) {
        console.error('Error fetching batch:', err);
        return null;
      }
    }

    /**
     * Fetches the ancestors of the given id
     * @param {number} id - ID of the node, ie: 18028
     * @returns {Object} - node_from_root object as returned from the server
     * {":id": [{}, {}, {}]}
     */
    async ancestors(id) {
      const query = new URLSearchParams({ 'node_ids[]': id });

      try {
        const response = await fetch(this.ancestorsUrl + '?' + query);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }
  }

  exports.InfiniteTreeFetch = InfiniteTreeFetch;
})(window);
