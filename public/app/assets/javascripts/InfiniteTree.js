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
      this.resourceUri = resourceUri; // TODO generalize away from resource
      this.repoId = resourceUri.split('/')[2];
      this.resourceId = resourceUri.split('/')[4]; // TODO generalize away from resource
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

      if (this.uriFragment === '') {
        this.renderRoot();
      } else {
        const nodeRecordId =
          this.uriFragment.split('_')[this.uriFragment.split('_').length - 1];
        const nodeElementId = this.uriFragment.replace('#tree::', '');

        this.allAncestorBatches(nodeRecordId)
          .then(data => {
            this.renderAncestors(data, nodeElementId);
          })
          .catch(error => {
            console.error('Error fetching ancestors:', error);
          });
      }
    }

    /**
     * Renders the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.getNodeData();
      const rootFragment = this.markup.root(this.markup.title(rootData));
      const rootNode = rootFragment.querySelector('li');

      if (rootData.child_count > 0) {
        rootNode.setAttribute('aria-expanded', 'true');

        await this.renderInitialBatchForNode(rootNode, rootData);
      }

      this.container.appendChild(rootFragment);
    }

    /**
     * Renders the first batch of children for any node
     * @param {HTMLElement} node - The node to render children for
     * @param {Object} nodeData - The node data from the server
     */
    async renderInitialBatchForNode(node, nodeData) {
      const batchData = this.prepareBatch(node, nodeData);
      const list = this.renderList(node, batchData.level, nodeData.waypoints);
      const observeForBatch = nodeData.waypoints > 1 ? 1 : null;

      this.renderBatch(list, batchData.nodes, 0, observeForBatch);
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
     * Renders a batch of child nodes into a list
     * @param {HTMLElement} list - The list element to render into
     * @param {array} nodes - Node objects to render
     * @param {number} batchNumber - The batch number being rendered
     * @param {number|null} observeForBatch - The number of a neighboring batch to observe for, null if none
     */
    renderBatch(list, nodes, batchNumber, observeForBatch = null) {
      if (!Array.isArray(nodes)) {
        console.error('renderBatch expected nodes to be an array, got:', nodes);
        return;
      }

      const listMeta = this.validateList(list);
      if (!listMeta) return;

      const batchFragment = this.buildBatchFragment(
        nodes,
        listMeta.level,
        listMeta.parentId,
        observeForBatch
      );

      const placeholder = list.querySelector(
        `li[data-batch-placeholder="${batchNumber}"]`
      );

      if (!placeholder) {
        console.error('renderBatch could not find placeholder for batch:', {
          batchNumber,
          parentId: listMeta.parentId,
          listHTML: list.innerHTML,
        });
        return;
      }

      placeholder.replaceWith(batchFragment);

      if (observeForBatch !== null) {
        const observerNode = list.querySelector('[data-observe-next-batch]');

        if (observerNode) {
          this.batchObserver.observe(observerNode);
        }
      }
    }

    /**
     * Builds a fragment containing a batch of child nodes
     * @param {array} nodes - Node objects to render
     * @param {number} level - The tree level for these nodes
     * @param {string} parentId - The ID of the parent node
     * @param {number|null} observeForBatch - The number of a neighboring batch to observe for, null if none
     * @returns {DocumentFragment} The built batch fragment
     */
    buildBatchFragment(nodes, level, parentId, observeForBatch = null) {
      const batchFragment = new DocumentFragment();

      nodes.forEach((node, i) => {
        const shouldObserveNode =
          i === Math.floor(this.BATCH_SIZE / 2) - 1 && observeForBatch !== null;

        batchFragment.appendChild(
          this.markup.node(
            node,
            level,
            shouldObserveNode,
            shouldObserveNode ? parentId : null,
            shouldObserveNode ? Number(observeForBatch) : null
          )
        );
      });

      return batchFragment;
    }

    /**
     * Gets node data from either root() or node() fetch methods
     * @param {number|null} nodeId - The node ID to fetch, null for root
     * @returns {Promise<Object>} Node data from the server
     */
    async getNodeData(nodeId = null) {
      return nodeId !== null
        ? await this.fetch.node(nodeId)
        : await this.fetch.root();
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
     * Builds the ancestor tree list
     * @param {Array} ancestorBatches - The ancestor batches to build the tree from
     * @param {string} nodeElementId - The HTML ID of the node element to scroll to
     */
    async renderAncestors(ancestorBatches, nodeElementId) {
      const ancestorsFrag = ancestorBatches.reduce((acc, batch, i) => {
        const numBatches = batch.waypoints;
        const nodeTitle = this.markup.title(batch);
        const ancestorHtmlId = batch.ancestorHtmlId;

        if (i === 0) {
          const treeListFrag = this.markup.rootList();
          const treeListElement = treeListFrag.querySelector('ol');

          const rootNodeFrag = this.markup.newRootNode(nodeTitle);
          const rootNodeElement = rootNodeFrag.querySelector('li');

          const nodeListFrag = this.markup.nodeList(
            ancestorHtmlId,
            i + 1,
            numBatches
          );
          const nodeListElement = nodeListFrag.querySelector('ol');

          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              batchData.hasOwnProperty('observeForBatch')
                ? Number(batchData.observeForBatch)
                : null
            );

            nodeListElement
              .querySelector(`li[data-batch-placeholder="${batchNumber}"]`)
              .replaceWith(batchFragment);
          });

          rootNodeElement.appendChild(nodeListFrag);

          treeListElement.appendChild(rootNodeFrag);

          acc.appendChild(treeListFrag);

          return acc;
        } else {
          const nodeElement = acc.querySelector(`li#${ancestorHtmlId}`);
          const icon = nodeElement.querySelector('.node-expand-icon');

          const nodeListFrag = this.markup.nodeList(
            ancestorHtmlId,
            i + 1,
            numBatches
          );

          const nodeListElement = nodeListFrag.querySelector('ol');

          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              batchData.hasOwnProperty('observeForBatch')
                ? Number(batchData.observeForBatch)
                : null
            );

            nodeListElement
              .querySelector(`li[data-batch-placeholder="${batchNumber}"]`)
              .replaceWith(batchFragment);
          });

          nodeElement.appendChild(nodeListFrag);

          nodeElement.setAttribute('data-has-expanded', 'true');
          nodeElement.setAttribute('aria-expanded', 'true');
          icon.classList.add('expanded');

          return acc;
        }
      }, new DocumentFragment());

      this.container.appendChild(ancestorsFrag);

      const nodeOfInterest = this.container.querySelector(`#${nodeElementId}`);
      const nodesToObserve = this.container.querySelectorAll(
        '[data-observe-next-batch]'
      );

      nodeOfInterest.classList.add('current');
      nodeOfInterest.scrollIntoView({ behavior: 'instant', block: 'center' });

      nodesToObserve.forEach(node => {
        this.batchObserver.observe(node);
      });
    }

    /**
     * Returns all ancestor batches for a given record ID
     * @param {number} id - The record ID of the node to fetch ancestor batches for
     * @returns {Promise<Array>} An array of ancestor batch data
     */
    async allAncestorBatches(id) {
      const ancestors = await this.fetch.ancestors(id);

      return Promise.all(
        ancestors[id].map(ancestor => this.ancestorBatchAndNeighbors(ancestor))
      );
    }

    /**
     * Fetches and returns the initial batch(es) for an ancestor; includes extra metadata
     * if a target batch's neighbor needs to be observed for its neighbor
     * @param {Object} ancestorMetaObj - The ancestor metadata object
     * @returns {Object} An object containing the ancestor's batch(es) and possible metadata
     */
    async ancestorBatchAndNeighbors(ancestorMetaObj) {
      // TODO: Provide `result` data from the server
      const isRoot = ancestorMetaObj.node === null;
      const recordId = isRoot
        ? this.resourceId
        : ancestorMetaObj.node.split('/')[4];
      const nodeId = isRoot ? null : recordId;
      const batchTarget = ancestorMetaObj.offset;
      const baseData = await this.getNodeData(nodeId);
      const numBatches = baseData.waypoints;

      const result = {
        batchTarget,
        ...Object.fromEntries(
          Object.entries(baseData).filter(
            ([key]) => !['precomputed_waypoints', 'waypoint_size'].includes(key)
          )
        ),
        batches: {},
        ancestorHtmlId: `${baseData.jsonmodel_type}_${recordId}`,
      };

      /**
       * Fetches a batch and returns it with optional metadata about the batch's neighbors
       * @param {number} batchNum - The batch number to fetch
       * @param {number} [observeForBatch=null] - The batch number to observe for loading its neighbor
       * @returns {Object} An object containing the batch data and possible metadata
       */
      const fetchBatch = async (batchNum, observeForBatch = null) => {
        let nodes;

        if (batchNum === 0) {
          nodes =
            baseData.precomputed_waypoints[
              isRoot ? '' : ancestorMetaObj.node
            ][0];
        } else {
          nodes = await this.fetch.batch(
            isRoot ? '' : ancestorMetaObj.node,
            batchNum
          );
        }

        const result = {
          nodes,
        };

        if (observeForBatch !== null) {
          result.observeForBatch = observeForBatch;
        }

        return result;
      };

      if (numBatches < 4) {
        result.batches[0] = await fetchBatch(0);
      }

      if (numBatches === 2) {
        result.batches[1] = await fetchBatch(1);
      }

      if (numBatches === 3) {
        if (batchTarget === 0) {
          result.batches[1] = await fetchBatch(1, 2);
        } else {
          result.batches[1] = await fetchBatch(1);
          result.batches[2] = await fetchBatch(2);
        }
      }

      if (numBatches >= 4) {
        if (batchTarget === 0) {
          result.batches[1] = await fetchBatch(1, 2);
        } else if (batchTarget === numBatches - 1) {
          result.batches[0] = await fetchBatch(0, 1);
          result.batches[numBatches - 2] = await fetchBatch(
            numBatches - 2,
            numBatches - 3
          );
          result.batches[numBatches - 1] = await fetchBatch(numBatches - 1);
        } else if (batchTarget === 1) {
          result.batches[0] = await fetchBatch(0);
          result.batches[1] = await fetchBatch(1);
          result.batches[2] = await fetchBatch(2, 3);
        } else if (batchTarget === numBatches - 2) {
          result.batches[0] = await fetchBatch(0, numBatches > 4 ? 1 : null);
          result.batches[numBatches - 3] = await fetchBatch(
            numBatches - 3,
            numBatches - 4 === 0 ? null : numBatches - 4
          );
          result.batches[batchTarget] = await fetchBatch(batchTarget);
          result.batches[numBatches - 1] = await fetchBatch(numBatches - 1);
        } else if (batchTarget === 2) {
          result.batches[0] = await fetchBatch(0);
          result.batches[1] = await fetchBatch(1);
          result.batches[2] = await fetchBatch(2, 3);
        } else {
          result.batches[0] = await fetchBatch(0, 1);
          result.batches[batchTarget - 1] = await fetchBatch(
            batchTarget - 1,
            batchTarget - 2
          );
          result.batches[batchTarget] = await fetchBatch(batchTarget);
          result.batches[batchTarget + 1] = await fetchBatch(
            batchTarget + 1,
            batchTarget + 2
          );
        }
      }

      return result;
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
          const parentNodeUri = node.getAttribute('data-observe-node'); // this attr needs to be renamed to data-parent-uri
          const siblingList = node.closest('.node-children');
          const batchOffset = Number(node.getAttribute('data-observe-offset'));
          const batchData = await this.fetch.batch(parentNodeUri, batchOffset);

          if (!batchData) {
            console.error('batchObserverHandler failed to fetch batch');
            return;
          }

          const batchOffsetPlaceholderEl = siblingList.querySelector(
            `li[data-batch-placeholder="${batchOffset}"]`
          );
          const observeForBatch =
            batchOffsetPlaceholderEl.nextElementSibling?.matches(
              'li[data-batch-placeholder]'
            )
              ? Number(
                  batchOffsetPlaceholderEl.nextElementSibling.getAttribute(
                    'data-batch-placeholder'
                  )
                )
              : batchOffsetPlaceholderEl.previousElementSibling?.matches(
                  'li[data-batch-placeholder]'
                )
              ? Number(
                  batchOffsetPlaceholderEl.previousElementSibling.getAttribute(
                    'data-batch-placeholder'
                  )
                )
              : null;

          this.renderBatch(
            siblingList,
            batchData,
            batchOffset,
            observeForBatch
          );

          node.removeAttribute('data-observe-next-batch');
          node.removeAttribute('data-observe-node');
          node.removeAttribute('data-observe-offset');
          observer.unobserve(node);

          if (observeForBatch !== null) {
            const nextNode = siblingList.querySelector(
              `[data-observe-next-batch][data-observe-offset="${observeForBatch}"]`
            ); // TODO the data-observe-next-batch attr should be renamed or removed, "next" is not holistic enough

            if (nextNode) {
              observer.observe(nextNode);
            } else {
              console.error(
                `batchObserverHandler could not find node to observe for batch ${observeForBatch}`
              );
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
        const nodeData = await this.getNodeData(Number(nodeRecordId));

        await this.renderInitialBatchForNode(node, nodeData);

        node.setAttribute('data-has-expanded', 'true');
      }

      node.setAttribute('aria-expanded', isExpanding ? 'true' : 'false');
      icon.classList.toggle('expanded');
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
