(function (exports) {
  class InfiniteTreeFetch {
    /**
     * @constructor
     * @param {string} fetchPrefix - Prefix prepended to the tree endpoints,
     * eg `AppConfig[:public_proxy_url]` or the relative `APP_PATH`; a trailing
     * slash is ignored
     * @param {string} rootUri - The URI of the tree root, ie a resource,
     * digital object, or classification
     */
    constructor(fetchPrefix, rootUri) {
      const baseUri = `${fetchPrefix.replace(/\/$/, '')}${rootUri}/tree`;

      this.rootUri = baseUri + '/root';
      this.nodeUri = baseUri + '/node';
      this.batchUri = baseUri + '/waypoint'; // TODO: rename endpoint to /batch
      this.ancestorsUri = baseUri + '/node_from_root'; // TODO: rename endpoint to /ancestors
    }

    /**
     * Fetches JSON, returning null on network or HTTP errors
     * @param {string} url - The URL to fetch
     * @returns {Promise<Object|Array|null>} - Parsed JSON or null
     */
    async #getJson(url) {
      try {
        const response = await fetch(url);

        if (!response.ok) {
          console.error(`InfiniteTreeFetch: ${response.status} for ${url}`);
          return null;
        }

        return await response.json();
      } catch (err) {
        console.error(err);
        return null;
      }
    }

    /**
     * Fetches the root
     * @returns {Promise<Object|null>} - Root object returned from the server
     */
    async root() {
      return this.#getJson(this.rootUri);
    }

    /**
     * Fetches the node with the given URI
     * @param {string} uri - URI of the node, ie: '/repositories/2/archival_objects/18028'
     * @returns {Promise<Object|null>} - Node object as returned from the server
     */
    async node(uri) {
      const query = new URLSearchParams();

      query.append('node', uri);

      return this.#getJson(this.nodeUri + '?' + query);
    }

    /**
     * Fetches the ancestors of the given id
     * @param {number|string} id - ID of the node, ie: 18028
     * @returns {Promise<Object|null>} - node_from_root object as returned from the server
     * {":id": [{}, {}, {}]}
     *
     * @todo: rename node_from_root to ancestors
     */
    async ancestors(id) {
      const query = new URLSearchParams();

      query.append('node_ids[]', id);

      return this.#getJson(this.ancestorsUri + '?' + query);
    }

    /**
     * Fetches a batch of the given parent's children
     * @param {string} parentRef - The parent reference for the endpoint; either '' for root,
     * or the URI of the parent node, ie: '/repositories/:rid/archival_objects/:id'
     * @param {number} offset - The `offset` URL param
     * @returns {Promise<Array|null>} - Array of node objects as returned from the server
     */
    async batch(parentRef, offset) {
      const query = new URLSearchParams();

      query.append('node', parentRef);
      query.append('offset', offset);

      return this.#getJson(this.batchUri + '?' + query);
    }
  }

  exports.InfiniteTreeFetch = InfiniteTreeFetch;
})(window);
