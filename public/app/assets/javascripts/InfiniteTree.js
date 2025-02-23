//= require InfiniteTreeFetch
//= require InfiniteTreeFragments

(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {number} childrenBatchSize - The number of nodes per batch of children
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     * @param {string} identifier_separator - The i18n identifier separator
     * @param {string} date_type_bulk - The i18n date type bulk
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(
      childrenBatchSize,
      appUrlPrefix,
      resourceUri,
      identifier_separator,
      date_type_bulk
    ) {
      this.CHILDREN_BATCH_SIZE = childrenBatchSize;
      this.resourceUri = resourceUri;
      this.repoId = resourceUri.split('/')[2];
      this.resourceId = resourceUri.split('/')[4];
      this.i18n = { sep: identifier_separator, bulk: date_type_bulk };

      this.container = document.querySelector('#infinite-tree-container');

      this.fetch = new InfiniteTreeFetch(appUrlPrefix, resourceUri);

      this.frag = new InfiniteTreeFragments(
        resourceUri,
        childrenBatchSize,
        this.i18n
      );

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
    }

    /**
     * Render the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.fetch.root();
      const rootFrag = this.frag.root(this.frag.buildNodeTitle(rootData));
      const rootNode = rootFrag.querySelector('.root.node');

      await this.renderInitialChildren(rootNode, rootData);

      this.container.appendChild(rootFrag);
    }

    /**
     * Render the first batch of a node's children
     * @param {HTMLElement} parent - The node element to initialize children for
     * @param {Object} data - The node data object from the server
     */
    async renderInitialChildren(parent, data) {
      const batchData = this.prepareBatchData(parent, data);
      const childrenList = this.renderChildrenList(
        parent,
        batchData.level,
        data.waypoints
      );

      this.renderBatchOfChildren(
        childrenList,
        batchData.nodes,
        batchData.hasNextBatch,
        0
      );
    }

    /**
     * Render the container structure for child nodes
     * @param {HTMLElement} parent - Parent node element
     * @param {number} parentLevel - Tree level of the parent
     * @param {number} numBatches - Number of batch placeholders to create
     * @returns {HTMLElement} The created children list element
     */
    renderChildrenList(parent, parentLevel, numBatches) {
      const childrenListFrag = this.frag.childrenList(
        parent.id,
        parentLevel + 1,
        numBatches
      );

      parent.appendChild(childrenListFrag);

      return parent.querySelector('.children');
    }

    /**
     * Render a batch of child nodes into a list
     * @param {HTMLElement} list - The list element to render into
     * @param {array} nodes - Node objects to render
     * @param {boolean} hasNextBatch - Whether there is another batch after this one
     * @param {number} batchNumber - The batch number being rendered
     */
    renderBatchOfChildren(list, nodes, hasNextBatch, batchNumber = 0) {
      if (!Array.isArray(nodes)) {
        console.error('Expected nodes to be an array, got:', nodes);
        return;
      }

      const listMeta = this.validateChildrenList(list);
      if (!listMeta) return;

      const batchFrag = new DocumentFragment();

      nodes.forEach((node, i) => {
        const observeThisNode =
          i == Math.floor(this.CHILDREN_BATCH_SIZE / 2) - 1 && hasNextBatch;
        const markupArgs = [node, listMeta.level, observeThisNode];

        if (observeThisNode) {
          markupArgs.push(listMeta.parentId, batchNumber + 1);
        }

        batchFrag.appendChild(this.frag.node(...markupArgs));
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

      placeholder.replaceWith(batchFrag);

      if (hasNextBatch) {
        const observerNode = list.querySelector('[data-observe-next-batch]');

        if (observerNode) {
          this.batchObserver.observe(observerNode);
        }
      }
    }

    /**
     * Prepare the data needed for rendering a batch of children
     * @param {HTMLElement} parent - Parent node element
     * @param {Object} data - Node data from the server
     * @param {number} batchNumber - Which batch of children to prepare
     * @returns {Object} Prepared batch data, {nodes:array, hasNextBatch:boolean, level:number}
     */
    prepareBatchData(parent, data, batchNumber = 0) {
      const isRoot = parent.classList.contains('root');
      const wpKey = isRoot ? '' : data.uri;
      const level = isRoot
        ? 0
        : Number(parent.closest('.children').getAttribute('data-tree-level'));

      return {
        nodes: data.precomputed_waypoints[wpKey][batchNumber],
        hasNextBatch: data.waypoints > batchNumber + 1,
        level: level,
      };
    }

    /**
     * Validate the list element and get its metadata
     * @param {HTMLElement} list - The list element to validate
     * @returns {Object|null} List metadata if valid, null if invalid
     */
    validateChildrenList(list) {
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
          const siblingList = node.closest('.children');
          const nextBatchNumber = Number(
            node.getAttribute('data-observe-offset')
          );
          const totalBatches = Number(
            siblingList.getAttribute('data-total-child-batches')
          );
          const hasNextBatch = nextBatchNumber + 1 < totalBatches;
          const batchData = await this.fetch.batch({
            node: parentNodeUri,
            offset: nextBatchNumber,
          });

          if (!batchData) {
            console.error('Failed to fetch batch');
            return;
          }

          this.renderBatchOfChildren(
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
     * Handle click events on expandme buttons or their child icons
     * @param {Event} e - Click event
     */
    async expandHandler(e) {
      const node = e.target.closest('.node');
      const isExpanding = node.getAttribute('aria-expanded') === 'false';
      const icon =
        e.target.closest('.expandme-icon') ||
        e.target.querySelector('.expandme-icon');

      if (isExpanding && node.getAttribute('data-has-expanded') === 'false') {
        const nodeRecordId = node.getAttribute('data-uri').split('/')[4];
        const nodeData = await this.fetch.node(Number(nodeRecordId));
        await this.renderInitialChildren(node, nodeData);
        node.setAttribute('data-has-expanded', 'true');
      }

      node.setAttribute('aria-expanded', isExpanding ? 'true' : 'false');
      icon.classList.toggle('expanded');
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
