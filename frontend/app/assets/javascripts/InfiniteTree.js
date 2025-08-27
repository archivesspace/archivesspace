//= require InfiniteTreeFetch
//= require InfiniteTreeMarkup
//= require InfiniteTreeResizer
//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {Object} initialContext - The data for the "current node"
     * @param {boolean} initialContext.isRoot - Whether the initial selection is the root
     * @param {string} initialContext.locationHash - window.location.hash
     * @param {string} initialContext.rootUri - The URI of the root record, e.g. "/repositories/1/resources/3"
     * @param {number} batchSize - The number of nodes per batch of children
     * @param {Object} i18n - The i18n object for use in a non .js.erb file
     * @param {string} i18n.sep - The identifier separator
     * @param {string} i18n.bulk - The date type bulk
     * @param {Object} i18n.enumerations - The enumeration translations object
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(initialContext, batchSize, i18n) {
      this.BATCH_SIZE = batchSize;
      this.rootMeta = {
        uri: initialContext.rootUri,
        ...InfiniteTreeIds.uriToParts(initialContext.rootUri),
      };

      this.container = document.querySelector('#infinite-tree-container');
      this.recordPaneEl = document.querySelector('#infinite-tree-record-pane');

      this.fetch = new InfiniteTreeFetch(initialContext.rootUri);

      this.markup = new InfiniteTreeMarkup(
        initialContext.rootUri,
        batchSize,
        i18n
      );

      new InfiniteTreeResizer(this.container);

      this.batchObserver = new IntersectionObserver(
        (entries, observer) => {
          this.#batchObserverHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '-30% 0px -30% 0px', // middle 40% of container
          threshold: 0,
        }
      );

      this.container.addEventListener('click', e => {
        if (e.target.closest('.node-expand')) this.#expandClickHandler(e);
        else if (e.target.closest('.record-title')) this.#titleClickHandler(e);
      });

      if (initialContext.isRoot) {
        this.renderRoot();
      } else {
        this.loadNodeWithAncestors(initialContext.locationHash);
      }
    }

    /**
     * Renders the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.fetch.node();
      const rootListFrag = this.markup.rootList();
      const rootListElement = rootListFrag.querySelector('ol');
      const rootNodeFrag = this.markup.rootNode(rootData);
      const rootNodeElement = rootNodeFrag.querySelector('li');

      rootNodeElement.classList.add('current');

      if (rootData.child_count > 0) {
        await this.#renderInitialBatchForNode(rootNodeElement, rootData);
      }

      rootListElement.appendChild(rootNodeFrag);

      this.container.appendChild(rootListFrag);
    }

    /**
     * Orchestrates the rendering of a node with all its ancestors on page load
     * @param {string} locationHash - The location hash representing the node to render
     */
    loadNodeWithAncestors(locationHash) {
      const nodeId = InfiniteTreeIds.parseTreeId(locationHash).id;
      const nodeElementId = InfiniteTreeIds.locationHashToHtmlId(locationHash);

      this.#fetchAncestorBatches(nodeId)
        .then(data => {
          this.#renderAncestors(data, nodeElementId);
        })
        .catch(error => {
          console.error('Error in #fetchAncestorBatches:', error);
        });
    }

    /**
     * Sets the current node and notifies the record pane
     * @param {HTMLElement} node - The node to set as current
     */
    setCurrentNode(node) {
      const old = this.container.querySelector('.current');
      if (old) old.classList.remove('current');

      node.classList.add('current');

      const nodeSelectEvent = new CustomEvent('infiniteTree:nodeSelect', {
        detail: {
          requestPath: AS.app_prefix(
            node.dataset.uri.split('/').slice(-2).join('/')
          ),
        },
      });

      this.recordPaneEl.dispatchEvent(nodeSelectEvent);
    }

    /**
     * Renders the first batch of children for any node
     * @param {HTMLElement} node - The node to render children for
     * @param {Object} nodeData - The node data from the server
     */
    async #renderInitialBatchForNode(node, nodeData) {
      const batchData = this.#prepareBatch(node, nodeData);
      const listFragment = this.markup.nodeList(
        node.id,
        batchData.level + 1,
        nodeData.waypoints
      );

      node.appendChild(listFragment);

      const list = node.querySelector('.node-children');
      const observeForBatch = nodeData.waypoints > 1 ? 1 : null;

      this.#renderBatch(list, batchData.nodes, 0, observeForBatch);
    }

    /**
     * Renders a batch of child nodes into a list
     * @param {HTMLElement} list - The list element to render into
     * @param {array} nodes - Node objects to render
     * @param {number} batchNumber - The batch number being rendered
     * @param {number|null} observeForBatch - The number of a neighboring batch to observe for, null if none
     */
    #renderBatch(list, nodes, batchNumber, observeForBatch = null) {
      const listMeta = this.#validateList(list);
      if (!listMeta) return;

      const batchFragment = this.#buildBatchFragment(
        nodes,
        listMeta.level,
        listMeta.parentId,
        observeForBatch
      );
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
    #buildBatchFragment(nodes, level, parentId, observeForBatch = null) {
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
     * Prepares the data needed for rendering a batch of children
     * @param {HTMLElement} parent - Parent node element
     * @param {Object} data - Node data from the server
     * @param {number} batchNumber - Which batch of children to prepare
     * @returns {Object} Prepared batch data, {nodes:array, hasNextBatch:boolean, level:number}
     */
    #prepareBatch(parent, data, batchNumber = 0) {
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
     * Fetches all ancestor batches for a given record ID
     * @param {number} id - The record ID of the node to fetch ancestor batches for
     * @returns {Promise<Array>} An array of ancestor batch data
     */
    async #fetchAncestorBatches(id) {
      const ancestors = await this.fetch.ancestors(id);

      return Promise.all(
        ancestors[id].map(ancestor =>
          this.#fetchAncestorBatchWithNeighbors(ancestor)
        )
      );
    }

    /**
     * Fetches the initial batch(es) for an ancestor; includes extra metadata
     * if a target batch's neighbor needs to be observed for its neighbor
     * @param {Object} ancestorMetaObj - The ancestor metadata object
     * @returns {Object} An object containing the ancestor's batch(es) and possible metadata
     */
    async #fetchAncestorBatchWithNeighbors(ancestorMetaObj) {
      const isRoot = ancestorMetaObj.node === null;
      const recordId = isRoot
        ? this.rootMeta.id
        : ancestorMetaObj.node.split('/')[4];
      const fetchNodeId = isRoot ? null : recordId;
      const batchTarget = ancestorMetaObj.offset;

      const baseData = await this.fetch.node(isRoot ? null : fetchNodeId);

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
       * Fetches a batch and returns it with optional metadata about the batch's neighbors;
       * defined as an arrow function to access `this.fetch`
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

        const result = { nodes };

        if (observeForBatch !== null) {
          result.observeForBatch = observeForBatch;
        }

        return result;
      };

      // Build a "window" of batches around the node of interest's batch to ensure complete tree data availability.
      // This window acts as a buffer for bi-directional infinite scrolling by pre-fetching batches adjacent to
      // the target batch so users can navigate without waiting for intersection observer-triggered lazy loading.
      // The window size and composition varies based on the target's position and its parent's total batch count.
      if (numBatches < 4) {
        result.batches[0] = await fetchBatch(0);

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
      }

      if (numBatches >= 4) {
        if (batchTarget === 0) {
          result.batches[0] = await fetchBatch(0);
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
          result.batches[2] = await fetchBatch(2);
          result.batches[3] = await fetchBatch(3, 4);
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
     * Builds the ancestor tree list
     * @param {Array} ancestorBatches - The ancestor batches to build the tree from
     * @param {string} nodeElementId - The HTML ID of the node element to scroll to
     */
    async #renderAncestors(ancestorBatches, nodeElementId) {
      const ancestorsFrag = ancestorBatches.reduce((acc, batch, i) => {
        const numBatches = batch.waypoints;
        const ancestorHtmlId = batch.ancestorHtmlId;

        if (i === 0) {
          const treeListFrag = this.markup.rootList();
          const treeListElement = treeListFrag.querySelector('ol');

          const rootNodeFrag = this.markup.rootNode(batch);
          const rootNodeElement = rootNodeFrag.querySelector('li');

          const nodeListFrag = this.markup.nodeList(
            ancestorHtmlId,
            i + 1,
            numBatches
          );
          const nodeListElement = nodeListFrag.querySelector('ol');

          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.#buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              Object.prototype.hasOwnProperty.call(batchData, 'observeForBatch')
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
          // Handle non-root ancestor nodes
          const nodeElement = acc.querySelector(`li#${ancestorHtmlId}`);
          const icon = nodeElement.querySelector('.node-expand-icon');

          const nodeListFrag = this.markup.nodeList(
            ancestorHtmlId,
            i + 1,
            numBatches
          );

          const nodeListElement = nodeListFrag.querySelector('ol');

          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.#buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              Object.prototype.hasOwnProperty.call(batchData, 'observeForBatch')
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

      if (nodeOfInterest) {
        this.setCurrentNode(nodeOfInterest);
        nodeOfInterest.scrollIntoView({ behavior: 'instant', block: 'center' });
      }

      nodesToObserve.forEach(node => {
        this.batchObserver.observe(node);
      });
    }

    /**
     * @param {HTMLElement} node - The node to expand
     */
    async #expandNode(node) {
      if (node.dataset.hasExpanded === 'false') {
        const nodeRecordId = node.getAttribute('data-uri').split('/')[4];
        const nodeData = await this.fetch.node(Number(nodeRecordId));

        await this.#renderInitialBatchForNode(node, nodeData);
        node.setAttribute('data-has-expanded', 'true');
      }

      node.querySelector('.node-expand-icon').classList.add('expanded');
      node.setAttribute('aria-expanded', 'true');
    }

    /**
     * @param {HTMLElement} node - The node to collapse
     */
    #collapseNode(node) {
      node.querySelector('.node-expand-icon').classList.remove('expanded');
      node.setAttribute('aria-expanded', 'false');
    }

    /**
     * IntersectionObserver callback for populating the next batch of children
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     * @param {IntersectionObserver} observer - The observer instance
     */
    #batchObserverHandler(entries, observer) {
      entries.forEach(async entry => {
        if (!entry.isIntersecting) return;

        const node = entry.target;
        const parentNodeUri = node.getAttribute('data-observe-node');
        const siblingList = node.closest('.node-children');
        const batchOffset = Number(node.getAttribute('data-observe-offset'));
        const batchData = await this.fetch.batch(parentNodeUri, batchOffset);

        if (!batchData) {
          console.error('#batchObserverHandler failed to fetch batch');
          return;
        }

        const batchOffsetPlaceholderEl = siblingList.querySelector(
          `li[data-batch-placeholder="${batchOffset}"]`
        );
        const observeForBatch = this.#observeForBatch(batchOffsetPlaceholderEl);

        this.#renderBatch(siblingList, batchData, batchOffset, observeForBatch);

        node.removeAttribute('data-observe-next-batch');
        node.removeAttribute('data-observe-node');
        node.removeAttribute('data-observe-offset');
        observer.unobserve(node);

        if (observeForBatch !== null) {
          const nextNode = siblingList.querySelector(
            `[data-observe-next-batch][data-observe-offset="${observeForBatch}"]`
          );

          if (nextNode) {
            observer.observe(nextNode);
          } else {
            console.error(
              `#batchObserverHandler could not find node to observe for batch ${observeForBatch}`
            );
          }
        }
      });
    }

    /**
     * @param {Event} e - The click event
     */
    async #expandClickHandler(e) {
      const node = e.target.closest('.node');
      const isExpanded = node.getAttribute('aria-expanded') === 'true';

      if (!isExpanded) {
        await this.#expandNode(node);
      } else {
        this.#collapseNode(node);
      }
    }

    /**
     * @param {Event} e - The click event
     */
    #titleClickHandler(e) {
      const node = e.target.closest('.node');

      this.setCurrentNode(node);

      if (node.getAttribute('aria-expanded') === 'false')
        this.#expandNode(node);
    }

    /**
     * Validates and returns parent data from a list
     * @param {HTMLElement} list - The list element with data attributes to validate
     * @returns {Object|null} List metadata if valid, null if invalid
     */
    #validateList(list) {
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
     * Identifies an adjacent batch placeholder and returns its batch number for observation
     * @param {HTMLElement} el - The element to check for a batch placeholder neighbor
     * @returns {number|null} The batch number to observe for, or null if none
     */
    #observeForBatch(el) {
      const nextSiblingIsAPlaceholder = el.nextElementSibling?.matches(
        'li[data-batch-placeholder]'
      );
      const prevSiblingIsAPlaceholder = el.previousElementSibling?.matches(
        'li[data-batch-placeholder]'
      );

      return nextSiblingIsAPlaceholder
        ? +el.nextElementSibling.getAttribute('data-batch-placeholder')
        : prevSiblingIsAPlaceholder
        ? +el.previousElementSibling.getAttribute('data-batch-placeholder')
        : null;
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
