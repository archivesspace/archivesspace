//= require InfiniteTreeFetch
//= require InfiniteTreeMarkup
//= require InfiniteTreeResizer
//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {number} batchSize - The number of nodes per batch of children
     * @param {string} uriFragment - The document's URI fragment
     * @param {string} rootUri - The URI of the root record, e.g. "/repositories/1/resources/3"
     * @param {Object} i18n - The i18n object for use in a non .js.erb file
     * @param {string} i18n.sep - The identifier separator
     * @param {string} i18n.bulk - The date type bulk
     * @param {Object} i18n.enumerations - The enumeration translations object
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(batchSize, uriFragment, rootUri, i18n) {
      this.BATCH_SIZE = batchSize;
      this.rootUri = rootUri;

      this.container = document.querySelector('#infinite-tree-container');
      this.recordPaneEl = document.querySelector('#infinite-tree-record-pane');

      this.fetch = new InfiniteTreeFetch(rootUri);

      this.markup = new InfiniteTreeMarkup(rootUri, batchSize, i18n);

      new InfiniteTreeResizer(this.container); // this could be abstracted out to the template level since its markup is there alongside the tree not within the tree

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

      this.container.addEventListener('click', e => {
        if (e.target.closest('.node-expand')) this.expandHandler(e);
        else if (e.target.closest('.node-title')) {
          const clickedNode = e.target.closest('.node');
          this.setCurrentNode(clickedNode);
        }
      });

      if (
        uriFragment === '' ||
        uriFragment === InfiniteTreeIds.treeLinkUrl(this.rootUri)
      ) {
        this.renderRoot();
      } else {
        const nodeId = InfiniteTreeIds.parseTreeId(uriFragment).id;
        const nodeElementId = InfiniteTreeIds.locationHashToHtmlId(uriFragment);

        this.allAncestorBatches(nodeId)
          .then(data => {
            this.renderAncestors(data, nodeElementId);
          })
          .catch(error => {
            console.error('Error in allAncestorBatches:', error);
          });
      }
    }

    /**
     * Sets the current node and notifiesthe record pane
     * @param {HTMLElement} node - The node to set as current
     */
    setCurrentNode(node) {
      const old = this.container.querySelector('.current');
      if (old) old.classList.remove('current');

      node.classList.add('current');

      const nodeSelectEvent = new CustomEvent('infiniteTree:nodeSelect', {
        detail: { recordPath: node.dataset.uri.split('/').slice(-2).join('/') },
      });

      this.recordPaneEl.dispatchEvent(nodeSelectEvent);
    }

    /**
     * Renders the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.fetch.root();
      const rootFragment = this.markup.root(rootData);
      const rootNode = rootFragment.querySelector('.root.node');

      rootNode.classList.add('current');

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
        const observeThisNode =
          i == Math.floor(this.BATCH_SIZE / 2) - 1 && hasNextBatch;
        const markupArgs = [node, listMeta.level, observeThisNode];

        if (observeThisNode) {
          markupArgs.push(listMeta.parentId, batchNumber + 1);
        }

        batchFragment.appendChild(this.markup.node(...markupArgs));
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
      const isRoot = ancestorMetaObj.node === null;
      const resourceId = this.rootUri.split('/')[4]; // Extract from rootUri instead of this.resourceId
      const recordId = isRoot ? resourceId : ancestorMetaObj.node.split('/')[4];
      const nodeId = isRoot ? null : recordId;
      const batchTarget = ancestorMetaObj.offset;

      // Get node data directly instead of using getNodeData method
      const baseData =
        nodeId !== null
          ? await this.fetch.node(nodeId)
          : await this.fetch.root();

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
    async renderAncestors(ancestorBatches, nodeElementId) {
      const ancestorsFrag = ancestorBatches.reduce((acc, batch, i) => {
        const numBatches = batch.waypoints;
        const ancestorHtmlId = batch.ancestorHtmlId;

        if (i === 0) {
          // Handle root node - use frontend's root() method
          const rootFrag = this.markup.root(batch);
          const rootElement = rootFrag.querySelector('.root.node');

          // Create list for root's children
          const listFrag = this.markup.list(ancestorHtmlId, i + 1, numBatches);
          const listElement = listFrag.querySelector('ol');

          // Populate batches
          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              Object.prototype.hasOwnProperty.call(batchData, 'observeForBatch')
                ? Number(batchData.observeForBatch)
                : null
            );

            listElement
              .querySelector(`li[data-batch-placeholder="${batchNumber}"]`)
              .replaceWith(batchFragment);
          });

          rootElement.appendChild(listFrag);
          acc.appendChild(rootFrag);

          return acc;
        } else {
          // Handle non-root ancestor nodes
          const nodeElement = acc.querySelector(`li#${ancestorHtmlId}`);
          const icon = nodeElement.querySelector('.node-expand-icon');

          // Create list for this node's children
          const listFrag = this.markup.list(ancestorHtmlId, i + 1, numBatches);
          const listElement = listFrag.querySelector('ol');

          // Populate batches
          Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
            const batchFragment = this.buildBatchFragment(
              batchData.nodes,
              i + 1,
              ancestorHtmlId,
              Object.prototype.hasOwnProperty.call(batchData, 'observeForBatch')
                ? Number(batchData.observeForBatch)
                : null
            );

            listElement
              .querySelector(`li[data-batch-placeholder="${batchNumber}"]`)
              .replaceWith(batchFragment);
          });

          nodeElement.appendChild(listFrag);

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
