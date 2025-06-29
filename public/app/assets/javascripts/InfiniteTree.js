//= require InfiniteTreeFetch
//= require InfiniteTreeMarkup

(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {number} batchSize - The number of nodes per batch of children
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     * @param {string} identifier_separator - The i18n identifier separator
     * @param {string} date_type_bulk - The i18n date type bulk
     * @param {string} uriFragment - The document's URI fragment
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(
      batchSize,
      appUrlPrefix,
      resourceUri,
      identifier_separator,
      date_type_bulk,
      uriFragment
    ) {
      this.uriFragment = uriFragment;
      this.BATCH_SIZE = batchSize;
      this.resourceUri = resourceUri;
      this.repoId = resourceUri.split('/')[2];
      this.resourceId = resourceUri.split('/')[4];
      this.i18n = { sep: identifier_separator, bulk: date_type_bulk };

      this.container = document.querySelector('#infinite-tree-container');

      this.fetch = new InfiniteTreeFetch(appUrlPrefix, resourceUri);

      this.markup = new InfiniteTreeMarkup(resourceUri, batchSize, this.i18n);

      this.batchObserver = new IntersectionObserver(
        (entries, observer) => {
          this.batchObserverHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '-30% 0px -30% 0px', // middle 40% of container
          threshold: 0,
        }
      );

      this.renderRoot();

      setTimeout(() => {
        this.expandNode(
          this.container.querySelector('#archival_object_4539'),
          '#archival_object_4583'
        );
      }, 1000);
    }

    /**
     * Expands a node to show its children, fetching them if necessary;
     * sets the current node if provided and scrolls to it
     * @param {HTMLElement} node - The node to expand
     * @param {string|null} [currentNodeSelector=null] - The full selector for the child node to set as current, null if none
     */
    async expandNode(node, currentNodeSelector = null) {
      if (!node || !node.classList.contains('node')) {
        console.error('Invalid node element provided to expandNode');
        return;
      }

      if (node.getAttribute('aria-expanded') === 'true') {
        return;
      }

      const icon = node.querySelector('.node-expand-icon');

      if (node.getAttribute('data-has-expanded') === 'true') {
        node.setAttribute('aria-expanded', 'true');
        if (icon) icon.classList.add('expanded');
      } else {
        const nodeRecordId = node.getAttribute('data-uri').split('/')[4];
        const nodeData = await this.fetch.node(Number(nodeRecordId));

        await this.renderInitialBatch(node, nodeData);

        node.setAttribute('data-has-expanded', 'true');
        node.setAttribute('aria-expanded', 'true');
        if (icon) icon.classList.add('expanded');
      }

      if (currentNodeSelector) {
        const currentNode = node.querySelector(currentNodeSelector);
        const containerRect = this.container.getBoundingClientRect();
        const nodeRect = currentNode.getBoundingClientRect();
        const scrollOffset = nodeRect.top - containerRect.top - 100;

        this.setCurrentNode(currentNode);

        this.container.scrollBy({
          top: scrollOffset,
          behavior: 'smooth',
        });
      }
    }

    /**
     * Sets a node as the current node in the tree by adding and removing the 'current' class
     * @param {HTMLElement} node - The node element to make current
     */
    setCurrentNode(node) {
      if (!node || !node.classList.contains('node')) {
        console.error('Invalid node element provided to setCurrentNode:', node);
        return;
      }

      const old = this.container.querySelector('.node.current');

      if (old) {
        old.classList.remove('current');
      }

      node.classList.add('current');
    }

    /**
     * Renders the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.fetch.root();
      const rootFragment = this.markup.root(this.markup.title(rootData));
      const rootNode = rootFragment.querySelector('.root.node');

      await this.renderInitialBatch(rootNode, rootData);

      this.container.appendChild(rootFragment);
    }

    /**
     * Renders the first batch of a node's children
     * @param {HTMLElement} parent - The node element to initialize children for
     * @param {Object} data - The node data object from the server
     */
    async renderInitialBatch(parent, data) {
      const batchData = this.prepareBatch(parent, data);
      const list = this.renderList(parent, batchData.level, data.waypoints);

      this.renderBatch(list, batchData.nodes, batchData.hasNextBatch, 0);
    }

    /**
     * Renders and returns the list element for child nodes
     * @param {HTMLElement} parent - Parent node element
     * @param {number} parentLevel - Tree level of the parent
     * @param {number} numBatches - Number of batch placeholders to create
     * @returns {HTMLElement} The rendered list element
     */
    renderList(parent, parentLevel, numBatches) {
      const listFragment = this.markup.list(
        parent.id,
        parentLevel + 1,
        numBatches
      );

      parent.appendChild(listFragment);

      return parent.querySelector('.node-children');
    }

    /**
     * Renders a single node element
     * @param {Object} nodeData - The node data from the server
     * @param {number} level - The tree level for this node
     * @param {boolean} shouldObserveNode - Whether this node should be observed for batch loading
     * @param {string} [parentId=null] - The ID of the parent node, required if observe is true
     * @param {number} [batchNumber=null] - The batch number, required if observe is true
     * @returns {Node} The rendered node element
     */
    renderNode(
      nodeData,
      level,
      shouldObserveNode,
      parentId = null,
      batchNumber = null
    ) {
      const markupArgs = [nodeData, level, shouldObserveNode];

      if (shouldObserveNode) {
        markupArgs.push(parentId, batchNumber);
      }

      return this.markup.node(...markupArgs);
    }

    /**
     * Renders a batch of child nodes into a list
     * @param {HTMLElement} list - The list element to render into
     * @param {array} nodes - Node objects to render
     * @param {boolean} hasNextBatch - Whether there is another batch after this one
     * @param {number} batchNumber - The batch number being rendered
     */
    renderBatch(list, nodes, hasNextBatch, batchNumber = 0) {
      if (!Array.isArray(nodes)) {
        console.error('Expected nodes to be an array, got:', nodes);
        return;
      }

      const listMeta = this.validateList(list);
      if (!listMeta) return;

      const batchFragment = new DocumentFragment();

      nodes.forEach((node, i) => {
        const shouldObserveNode =
          i == Math.floor(this.BATCH_SIZE / 2) - 1 && hasNextBatch;

        const nodeElement = this.renderNode(
          node,
          listMeta.level,
          shouldObserveNode,
          shouldObserveNode ? listMeta.parentId : null,
          shouldObserveNode ? batchNumber + 1 : null
        );

        batchFragment.appendChild(nodeElement);
      });

      const placeholder = list.querySelector(
        `li[data-batch-placeholder="${batchNumber}"]`
      );

      if (!placeholder) {
        console.error('Could not find placeholder for batch:', {
          batchNumber,
          parentId: listMeta.parentId,
          listHTML: list.innerHTML,
        });
        return;
      }

      placeholder.replaceWith(batchFragment);

      if (hasNextBatch) {
        const observerNode = list.querySelector('[data-observe-next-batch]');

        if (observerNode) {
          this.batchObserver.observe(observerNode);
        }
      }
    }

    /**
     * Prepares the data needed for rendering a batch of children
     * @param {HTMLElement} parent - Parent node element
     * @param {Object} data - Node data from the server
     * @param {number} batchNumber - Which batch of children to prepare
     * @returns {Object} Prepared batch data, {nodes:array, hasNextBatch:boolean, level:number}
     */
    prepareBatch(parent, data, batchNumber = 0) {
      const isRoot = parent.classList.contains('root');
      const wpKey = isRoot ? '' : data.uri;
      const level = isRoot
        ? 0
        : Number(
            parent.closest('.node-children').getAttribute('data-tree-level')
          );

      return {
        nodes: data.precomputed_waypoints[wpKey][batchNumber],
        hasNextBatch: data.waypoints > batchNumber + 1,
        level: level,
      };
    }

    /**
     * Validates and returns parent data from a list
     * @param {HTMLElement} list - The list element with data attributes to validate
     * @returns {Object|null} List metadata if valid, null if invalid
     */
    validateList(list) {
      if (!list) {
        console.error('List element is null or undefined');
        return null;
      }

      const parentId = list.getAttribute('data-parent-id');
      if (!parentId) {
        console.error('List element is missing data-parent-id attribute');
        return null;
      }

      const level = Number(list.getAttribute('data-tree-level'));
      if (!level) {
        console.error('List element is missing data-tree-level attribute');
        return null;
      }

      return { parentId, level };
    }

    /**
     * IntersectionObserver callback for populating the next batch of children
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     * @param {IntersectionObserver} observer - The observer instance
     */
    batchObserverHandler(entries, observer) {
      entries.forEach(async entry => {
        if (entry.isIntersecting) {
          const node = entry.target;
          const parentNodeUri = node.getAttribute('data-observe-node');
          const siblingList = node.closest('.node-children');
          const nextBatchNumber = Number(
            node.getAttribute('data-observe-offset')
          );
          const totalBatches = Number(
            siblingList.getAttribute('data-total-child-batches')
          );
          const hasNextBatch = nextBatchNumber + 1 < totalBatches;
          const batchData = await this.fetch.batch(
            parentNodeUri,
            nextBatchNumber
          );

          if (!batchData) {
            console.error('Failed to fetch batch');
            return;
          }

          this.renderBatch(
            siblingList,
            batchData,
            hasNextBatch,
            nextBatchNumber
          );

          node.removeAttribute('data-observe-next-batch');
          node.removeAttribute('data-observe-node');
          node.removeAttribute('data-observe-offset');
          observer.unobserve(node);

          if (hasNextBatch) {
            const nextNode = siblingList.querySelector(
              `[data-observe-next-batch][data-observe-offset="${
                nextBatchNumber + 1
              }"]`
            );

            if (nextNode) {
              observer.observe(nextNode);
            } else {
              console.error('Could not find node to observe for next batch');
            }
          }
        }
      });
    }

    /**
     * Handles click events on expand buttons
     * @param {Event} e - Click event
     */
    async expandHandler(e) {
      const node = e.target.closest('.node');
      const isExpanding = node.getAttribute('aria-expanded') === 'false';
      const icon =
        e.target.closest('.node-expand-icon') ||
        e.target.querySelector('.node-expand-icon');

      if (isExpanding && node.getAttribute('data-has-expanded') === 'false') {
        const nodeRecordId = node.getAttribute('data-uri').split('/')[4];
        const nodeData = await this.fetch.node(Number(nodeRecordId));

        await this.renderInitialBatch(node, nodeData);

        node.setAttribute('data-has-expanded', 'true');
      }

      node.setAttribute('aria-expanded', isExpanding ? 'true' : 'false');
      icon.classList.toggle('expanded');
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
