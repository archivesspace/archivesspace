(function (exports) {
  class InfiniteTreeFetch {
    /**
     * @constructor
     * @param {string} rootRecordUri - The URI of the root record, e.g. "/repositories/1/resources/3"
     */
    constructor(rootRecordUri) {
      this.rootRecordUri = rootRecordUri;
      this.repoId = rootRecordUri.split('/')[2];
      this.rootRecordTypePlural = rootRecordUri.split('/')[3];
      this.rootRecordId = rootRecordUri.split('/')[4];
      this.baseEndpoint = `/${this.rootRecordTypePlural}/${this.rootRecordId}/tree`;
      this.rootNodeEndpoint = `${this.baseEndpoint}/root`;
      this.nodeEndpoint = `${this.baseEndpoint}/node`;
      this.batchEndpoint = `${this.baseEndpoint}/waypoint`; // TODO: rename endpoint to /batch
    }

    /**
     * Fetches the root
     * @returns {Object} - Root object returned from the server
     */
    async root() {
      try {
        const response = await fetch(AS.app_prefix(this.rootNodeEndpoint));

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
        const response = await fetch(
          `${AS.app_prefix(this.nodeEndpoint)}?${query}`
        );

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
        const response = await fetch(
          `${AS.app_prefix(this.batchEndpoint)}?${query}`
        );

        return await response.json();
      } catch (err) {
        console.error('Error fetching batch:', err);
        return null;
      }
    }
  }

  exports.InfiniteTreeFetch = InfiniteTreeFetch;
})(window);
