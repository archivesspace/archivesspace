(function (exports) {
  class InfiniteTreeFetch {
    /**
     * @constructor
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     */
    constructor(appUrlPrefix, resourceUri) {
      const baseUri = appUrlPrefix + resourceUri + '/tree';
      this.rootUri = baseUri + '/root';
      this.nodeUri = baseUri + '/node';
      this.batchUri = baseUri + '/waypoint'; // TODO: rename endpoint to /batch
      this.ancestorsUri = baseUri + '/node_from_root'; // TODO: rename endpoint to /ancestors
      this.repoId = resourceUri.split('/')[2];
    }

    /**
     * Fetches the root
     * @returns {Object} - Root object returned from the server
     */
    async root() {
      try {
        const response = await fetch(this.rootUri);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetches the node with the given id
     * @param {number} id - ID of the node, ie: 18028
     * @returns {Object} - Node object as returned from the server
     */
    async node(id) {
      const query = new URLSearchParams();

      query.append(
        'node',
        `/repositories/${this.repoId}/archival_objects/${id}`
      );

      try {
        const response = await fetch(this.nodeUri + '?' + query);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetches the ancestors of the given id
     * @param {number} id - ID of the node, ie: 18028
     * @returns {Object} - node_from_root object as returned from the server
     * {":id": [{}, {}, {}]}
     *
     * @todo: rename node_from_root to ancestors
     */
    async ancestors(id) {
      const query = new URLSearchParams();

      query.append('node_ids[]', id);

      try {
        const response = await fetch(this.ancestorsUri + '?' + query);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetches a batch of the given parent's children
     * @param {string} parentRef - The parent reference for the endpoint; either '' for root,
     * or the URI of the parent node, ie: '/repositories/:rid/archival_objects/:id'
     * @param {number} offset - The `offset` URL param
     * @returns {array} - Array of node objects as returned from the server
     */
    async batch(parentRef, offset) {
      const query = new URLSearchParams();

      query.append('node', parentRef);
      query.append('offset', offset);

      try {
        const response = await fetch(this.batchUri + '?' + query);

        return await response.json();
      } catch (err) {
        console.error('Error fetching batch:', err);
        return null;
      }
    }
  }

  exports.InfiniteTreeFetch = InfiniteTreeFetch;
})(window);
