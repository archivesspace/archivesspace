//= require InfiniteTreeIds
//= require InfiniteTreeFetch
//= require InfiniteTreeMarkup

(function (exports) {
  /**
   * Public (PUI) InfiniteTree. One core used by three consumers:
   * - Collection organization: `#tree::` hash links, title clicks handled by
   *   InfiniteRecords, current node synced through an InfiniteCoordinator,
   *   initial node from the URI fragment
   * - Record show-page sidebars: record links, normal navigation, current
   *   node from the page's record URI (ancestors and the current node expanded)
   * - Classification search subgroups: record links, no current node,
   *   several independent instances per page
   */
  class InfiniteTree {
    /**
     * @param {Object} options
     * @param {HTMLElement} options.container - Element the tree renders into;
     * it must be the scroll container (fixed height, `overflow-y: auto`)
     * @param {string} options.rootUri - URI of the tree root (resource,
     * digital object, or classification)
     * @param {number|string} options.batchSize - Number of nodes per batch of children
     * @param {string} options.fetchPrefix - Prefix for tree endpoint requests
     * @param {Object} options.i18n - {sep, classificationSep, bulk}
     * @param {string} [options.titleRules] - 'collection-organization' (default) or 'record'
     * @param {function(Object): string} [options.linkFor] - Node data => title href;
     * defaults to the collection-organization `#tree::` hash
     * @param {function(Event): void} [options.onTitleClick] - Called for clicks
     * on node titles; when absent the link navigates normally
     * @param {InfiniteCoordinator} [options.coordinator] - Collection organization only
     * @param {string} [options.uriFragment=''] - Collection organization only;
     * the document's URI fragment used to choose the initial node
     * @param {string} [options.currentUri] - URI of the current record; takes
     * precedence over `uriFragment`
     * @param {boolean} [options.expandCurrent=false] - Expand the current node
     * once it is rendered
     * @param {string} [options.scroll='center'] - How to bring the initial
     * node into view: 'center' (scrollIntoView, may scroll the page) or
     * 'container' (scroll only the tree container)
     */
    constructor({
      container,
      rootUri,
      batchSize,
      fetchPrefix,
      i18n,
      titleRules,
      linkFor,
      onTitleClick = null,
      coordinator = null,
      uriFragment = '',
      currentUri = null,
      expandCurrent = false,
      scroll = 'center',
    }) {
      const root = InfiniteTreeIds.parseUri(rootUri);

      this.container = container;
      this.rootUri = rootUri;
      this.rootType = root.type;
      this.repoId = root.repoId;
      this.BATCH_SIZE = Number(batchSize);
      this.i18n = i18n;
      this.onTitleClick = onTitleClick;
      this.coordinator = coordinator;
      this.uriFragment = uriFragment || '';
      this.pageCurrentUri = currentUri;
      this.expandCurrent = expandCurrent;
      this.scroll = scroll;

      /** @type {HTMLElement|null} The treeitem holding tabindex="0" */
      this.activeItem = null;

      this.fetch = new InfiniteTreeFetch(fetchPrefix, rootUri);

      this.markup = new InfiniteTreeMarkup({
        rootUri,
        batchSize: this.BATCH_SIZE,
        i18n,
        titleRules,
        linkFor,
      });

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

      this.container.addEventListener('click', e => this.clickHandler(e));
      this.container.addEventListener('keydown', e => this.keydownHandler(e));
      this.container.addEventListener('focusin', e => this.focusinHandler(e));

      if (this.coordinator && this.coordinator.registerTree) {
        this.coordinator.registerTree(this);
      }

      /** @type {Promise<void>} Resolves once the initial render completes */
      this.ready = this.load();
    }

    /**
     * Href for a node on record-linked trees: the slugged URL when human
     * readable URLs are enabled, otherwise the prefixed record URI
     * @param {Object} data - Node data from the server
     * @returns {string} - The href
     */
    static recordLink(data) {
      return data.slugged_url && data.slugged_url.length > 0
        ? data.slugged_url
        : AS.app_prefix(data.uri);
    }

    /**
     * Boots a record-linked tree (show-page sidebar or search subgroups) from
     * a container rendered by `shared/_infinite_tree_record_container`
     * @param {HTMLElement} container - The container with its data attributes
     * @returns {InfiniteTree|null} - The tree, or null without a container
     */
    static fromRecordContainer(container) {
      if (!container) return null;

      const data = container.dataset;
      const currentUri = data.currentUri || null;

      return new InfiniteTree({
        container,
        rootUri: data.rootUri,
        currentUri,
        batchSize: data.batchSize,
        fetchPrefix: APP_PATH,
        i18n: {
          sep: data.identifierSeparator,
          classificationSep: data.classificationIdentifierSeparator,
          bulk: data.dateTypeBulk,
        },
        titleRules: 'record',
        linkFor: InfiniteTree.recordLink,
        expandCurrent: currentUri !== null,
        scroll: 'container',
      });
    }

    /**
     * The URI of the current record: the coordinator's when there is one,
     * otherwise the page's record
     * @returns {string|null}
     */
    get currentUri() {
      return this.coordinator
        ? this.coordinator.currentRecord
        : this.pageCurrentUri;
    }

    /**
     * Determines the record whose path should be rendered on load
     * @returns {string|null} - A record URI, or null to render the root
     */
    initialTargetUri() {
      if (this.pageCurrentUri) return this.pageCurrentUri;

      const hash = InfiniteTreeIds.parseLocationHash(this.uriFragment);

      if (!hash) return null;

      if (InfiniteTreeIds.isRootType(hash.type)) return this.rootUri;

      return InfiniteTreeIds.childUri(this.rootUri, hash.id);
    }

    /**
     * Renders the initial tree: either the root and its first batch, or the
     * path of ancestors down to the target record. Falls back to the root if
     * the ancestor path cannot be fetched.
     */
    async load() {
      const targetUri = this.initialTargetUri();

      if (targetUri && targetUri !== this.rootUri) {
        const targetId = InfiniteTreeIds.parseUri(targetUri).id;
        let ancestorBatches = null;

        try {
          ancestorBatches = await this.allAncestorBatches(targetId);
        } catch (error) {
          console.error('Error fetching ancestors:', error);
        }

        if (ancestorBatches) {
          await this.renderAncestorsAndShow(
            ancestorBatches,
            InfiniteTreeIds.uriToElementId(targetUri)
          );
          this.initRovingTabindex();
          return;
        }
      }

      await this.renderRoot();

      if (this.pageCurrentUri === this.rootUri) {
        this.markCurrent(this.rootUri);
      }

      this.initRovingTabindex();
    }

    /**
     * Renders the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.getNodeData();

      if (!rootData) {
        console.error('InfiniteTree could not fetch the tree root');
        return;
      }

      const rootListFrag = this.markup.rootList();
      const rootListElement = rootListFrag.querySelector('ol');
      const rootNodeFrag = this.markup.rootNode(rootData);
      const rootNodeElement = rootNodeFrag.querySelector('li');

      if (rootData.child_count > 0) {
        await this.renderInitialBatchForNode(rootNodeElement, rootData);
      }

      rootListElement.appendChild(rootNodeFrag);

      this.container.appendChild(rootListFrag);
    }

    /**
     * Renders the first batch of children for any node
     * @param {HTMLElement} node - The node to render children for
     * @param {Object} nodeData - The node data from the server
     */
    async renderInitialBatchForNode(node, nodeData) {
      const batchData = this.prepareBatch(node, nodeData);
      const listFragment = this.markup.nodeList(
        node.id,
        batchData.level + 1,
        nodeData.waypoints
      );

      node.appendChild(listFragment);

      const list = node.querySelector('.node-children');
      const observeForBatch = nodeData.waypoints > 1 ? 1 : null;

      this.renderBatch(list, batchData.nodes, 0, observeForBatch);
    }

    /**
     * Renders a batch of child nodes into a list
     * @param {HTMLElement} list - The list element to render into
     * @param {array} nodes - Node objects to render
     * @param {number} batchNumber - The batch number being rendered
     * @param {number|null} observeForBatch - The number of a neighboring batch to observe for, null if none
     */
    renderBatch(list, nodes, batchNumber, observeForBatch = null) {
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
      const currentUri = this.currentUri;

      if (currentUri && !this.container.querySelector('.node.current')) {
        const currentNode = batchFragment.querySelector(
          `[data-uri="${currentUri}"]`
        );

        if (currentNode) this.setCurrentState(currentNode, true);
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
     * @param {string|null} nodeUri - The node URI to fetch, null for root
     * @returns {Promise<Object|null>} Node data from the server
     */
    async getNodeData(nodeUri = null) {
      return nodeUri !== null
        ? await this.fetch.node(nodeUri)
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
     * Renders batches of the given ancestor batch list into a node list
     * @param {Object} batch - An ancestor batch object
     * @param {number} level - The tree level of the batch's nodes
     * @returns {DocumentFragment} The populated node list
     */
    buildAncestorList(batch, level) {
      const ancestorHtmlId = batch.ancestorHtmlId;
      const nodeListFrag = this.markup.nodeList(
        ancestorHtmlId,
        level,
        batch.waypoints
      );
      const nodeListElement = nodeListFrag.querySelector('ol');

      Object.entries(batch.batches).forEach(([batchNumber, batchData]) => {
        const batchFragment = this.buildBatchFragment(
          batchData.nodes,
          level,
          ancestorHtmlId,
          Object.prototype.hasOwnProperty.call(batchData, 'observeForBatch')
            ? Number(batchData.observeForBatch)
            : null
        );

        nodeListElement
          .querySelector(`li[data-batch-placeholder="${batchNumber}"]`)
          .replaceWith(batchFragment);
      });

      return nodeListFrag;
    }

    /**
     * Builds the ancestor tree list, then marks and reveals the node of interest
     * @param {Array} ancestorBatches - The ancestor batches to build the tree from
     * @param {string} nodeElementId - The HTML ID of the node element to show
     */
    async renderAncestorsAndShow(ancestorBatches, nodeElementId) {
      const ancestorsFrag = ancestorBatches.reduce((acc, batch, i) => {
        const nodeListFrag = this.buildAncestorList(batch, i + 1);

        if (i === 0) {
          const treeListFrag = this.markup.rootList();
          const treeListElement = treeListFrag.querySelector('ol');
          const rootNodeFrag = this.markup.rootNode(batch);
          const rootNodeElement = rootNodeFrag.querySelector('li');

          rootNodeElement.appendChild(nodeListFrag);
          treeListElement.appendChild(rootNodeFrag);
          acc.appendChild(treeListFrag);
        } else {
          const nodeElement = acc.querySelector(`li#${batch.ancestorHtmlId}`);

          nodeElement.appendChild(nodeListFrag);
          nodeElement
            .querySelector(':scope > .node-row .node-expand')
            .setAttribute('data-has-expanded', 'true');
          this.syncExpandedState(nodeElement, true);
        }

        return acc;
      }, new DocumentFragment());

      this.container.appendChild(ancestorsFrag);

      const nodeOfInterest = this.container.querySelector(`#${nodeElementId}`);
      const nodesToObserve = this.container.querySelectorAll(
        '[data-observe-next-batch]'
      );

      if (nodeOfInterest) {
        this.markCurrentElement(nodeOfInterest);

        if (this.expandCurrent) {
          await this.setExpanded(nodeOfInterest, true);
        }

        this.scrollToNode(nodeOfInterest);
      }

      nodesToObserve.forEach(node => {
        this.batchObserver.observe(node);
      });
    }

    /**
     * Brings a node into view according to `this.scroll`
     * @param {HTMLElement} node - The node to reveal
     */
    scrollToNode(node) {
      if (this.scroll === 'container') {
        const row = node.querySelector(':scope > .node-row') || node;
        const offset =
          row.getBoundingClientRect().top -
          this.container.getBoundingClientRect().top;

        // Mirror LargeTree: put the node near the top of the tree, never
        // scrolling the page itself
        this.container.scrollTop += offset - 50;
      } else {
        node.scrollIntoView({ behavior: 'instant', block: 'center' });
      }
    }

    /**
     * Returns all ancestor batches for a given record ID
     * @param {number|string} id - The record ID of the node to fetch ancestor batches for
     * @returns {Promise<Array>} An array of ancestor batch data
     * @throws {Error} If the ancestors cannot be fetched
     */
    async allAncestorBatches(id) {
      const ancestors = await this.fetch.ancestors(id);

      if (!ancestors || !Array.isArray(ancestors[id])) {
        throw new Error(`No ancestors returned for node ${id}`);
      }

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
      const nodeUri = isRoot ? null : ancestorMetaObj.node;
      const batchTarget = ancestorMetaObj.offset;
      const baseData = await this.getNodeData(nodeUri);

      if (!baseData) {
        throw new Error(`Could not fetch tree node ${nodeUri || 'root'}`);
      }

      const numBatches = baseData.waypoints;

      const result = {
        batchTarget,
        ...Object.fromEntries(
          Object.entries(baseData).filter(
            ([key]) => !['precomputed_waypoints', 'waypoint_size'].includes(key)
          )
        ),
        batches: {},
        ancestorHtmlId: InfiniteTreeIds.uriToElementId(
          isRoot ? this.rootUri : nodeUri
        ),
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

        if (!nodes) {
          throw new Error(`Could not fetch batch ${batchNum}`);
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
          const parentNodeUri = node.getAttribute('data-parent-uri');
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

          if (!batchOffsetPlaceholderEl) return;

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
          node.removeAttribute('data-parent-uri');
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
                `batchObserverHandler could not find node to observe for batch ${observeForBatch}`
              );
            }
          }
        }
      });
    }

    /**
     * Delegates click events within the tree container
     * @param {MouseEvent} e - Click event
     */
    clickHandler(e) {
      if (e.target.closest('.node-expand')) {
        this.expandHandler(e);
      } else if (this.onTitleClick && e.target.closest('.node-title')) {
        this.onTitleClick(e);
      }
    }

    /**
     * Handles click events on expand buttons
     * @param {Event} e - Click event
     */
    async expandHandler(e) {
      const button = e.target.closest('.node-expand');
      const node = button.closest('.node');
      const isExpanding = button.getAttribute('aria-expanded') === 'false';

      await this.setExpanded(node, isExpanding);
    }

    /**
     * Expands or collapses a node, fetching its first batch of children the
     * first time it is expanded
     * @param {HTMLElement} node - The `li.node` to expand or collapse
     * @param {boolean} expand - True to expand, false to collapse
     */
    async setExpanded(node, expand) {
      const button = node.querySelector(':scope > .node-row .node-expand');

      if (!button) return;

      const hasExpanded = button.getAttribute('data-has-expanded') === 'true';

      // The latest request wins if the user toggles while children load
      node.setAttribute('data-expand-intent', expand ? 'true' : 'false');

      if (expand && !hasExpanded) {
        if (node.hasAttribute('data-loading-children')) return;

        node.setAttribute('data-loading-children', 'true');

        const nodeData = await this.getNodeData(node.getAttribute('data-uri'));

        node.removeAttribute('data-loading-children');

        if (!nodeData) return;

        await this.renderInitialBatchForNode(node, nodeData);

        button.setAttribute('data-has-expanded', 'true');
      }

      const expanded = node.getAttribute('data-expand-intent') === 'true';

      this.syncExpandedState(node, expanded);

      // Never leave the tab stop inside a collapsed subtree
      if (
        !expanded &&
        this.activeItem &&
        node.querySelector(':scope > .node-children')?.contains(this.activeItem)
      ) {
        this.setActiveItem(this.treeitemOf(node));
      }
    }

    /**
     * Sets every expanded-state indicator on a node with children
     * @param {HTMLElement} node - The `li.node`
     * @param {boolean} expanded - The new state
     */
    syncExpandedState(node, expanded) {
      const value = expanded ? 'true' : 'false';
      const button = node.querySelector(':scope > .node-row .node-expand');
      const icon = button && button.querySelector('.node-expand-icon');
      const item = this.treeitemOf(node);

      node.setAttribute('data-is-expanded', value);

      if (button) button.setAttribute('aria-expanded', value);
      if (icon) icon.classList.toggle('expanded', expanded);
      if (item) item.setAttribute('aria-expanded', value);
    }

    /**
     * Marks the node for the given URI as current, clearing any other
     * @param {string|null} uri - Record URI
     */
    markCurrent(uri) {
      const node = uri
        ? this.container.querySelector(`.node[data-uri="${uri}"]`)
        : null;

      if (node) {
        this.markCurrentElement(node);
      } else {
        this.clearCurrent();
      }
    }

    /**
     * Marks a node element as current, clearing any other
     * @param {HTMLElement} node - The `li.node`
     */
    markCurrentElement(node) {
      this.clearCurrent();
      this.setCurrentState(node, true);

      // Tabbing into the tree lands on the current node (or its nearest
      // visible ancestor), unless the user is already navigating inside it
      if (!this.container.contains(document.activeElement)) {
        this.setActiveItem(this.nearestVisibleItem(node));
      }
    }

    /**
     * Removes the current state from all nodes
     */
    clearCurrent() {
      this.container
        .querySelectorAll('.node.current')
        .forEach(n => this.setCurrentState(n, false));
    }

    /**
     * Toggles the current class, and `aria-current="page"` when the current
     * node is the page's own record
     * @param {HTMLElement} node - The `li.node`
     * @param {boolean} isCurrent - The new state
     */
    setCurrentState(node, isCurrent) {
      const item = this.treeitemOf(node);

      node.classList.toggle('current', isCurrent);

      if (!item) return;

      if (isCurrent && this.pageCurrentUri) {
        item.setAttribute('aria-current', 'page');
      } else {
        item.removeAttribute('aria-current');
      }
    }

    /**
     * @param {HTMLElement} node - A `li.node`
     * @returns {HTMLElement|null} - The node's own treeitem (title link)
     */
    treeitemOf(node) {
      return node
        ? node.querySelector(':scope > .node-row [role="treeitem"]')
        : null;
    }

    /**
     * @param {HTMLElement} item - A treeitem
     * @returns {HTMLElement} - The treeitem's `li.node`
     */
    nodeOf(item) {
      return item.closest('.node');
    }

    /**
     * Gives the current node, or the root, the tree's single tab stop
     */
    initRovingTabindex() {
      const current = this.container.querySelector('.node.current');

      this.setActiveItem(
        current
          ? this.nearestVisibleItem(current)
          : this.treeitemOf(this.container.querySelector('.root.node'))
      );
    }

    /**
     * Moves the roving tab stop to the given treeitem
     * @param {HTMLElement|null} item - The treeitem to make tabbable
     * @param {boolean} [focus=false] - Also move focus to it
     */
    setActiveItem(item, focus = false) {
      if (!item) return;

      if (this.activeItem && this.activeItem !== item) {
        this.activeItem.setAttribute('tabindex', '-1');
      }

      item.setAttribute('tabindex', '0');
      this.activeItem = item;

      if (focus) item.focus();
    }

    /**
     * Keeps the roving tab stop on whatever node last received focus,
     * including by pointer
     * @param {FocusEvent} e - Focusin event
     */
    focusinHandler(e) {
      const node = e.target.closest('.node');

      if (node && this.container.contains(node)) {
        this.setActiveItem(this.treeitemOf(node));
      }
    }

    /**
     * @param {HTMLElement} item - A treeitem
     * @returns {boolean} - True unless it is inside a collapsed node
     */
    isItemVisible(item) {
      return !item.closest('.node[data-is-expanded="false"] .node-children');
    }

    /**
     * @param {HTMLElement} node - A `li.node`
     * @returns {HTMLElement|null} - The node's treeitem, or that of its
     * nearest ancestor that is not hidden inside a collapsed node
     */
    nearestVisibleItem(node) {
      let current = node;

      while (current) {
        const item = this.treeitemOf(current);

        if (item && this.isItemVisible(item)) return item;

        current =
          current.parentElement && current.parentElement.closest('.node');
      }

      return null;
    }

    /**
     * Treeitems not hidden inside a collapsed node, in document order
     * @returns {HTMLElement[]}
     */
    visibleItems() {
      return Array.from(
        this.container.querySelectorAll('[role="treeitem"]')
      ).filter(item => this.isItemVisible(item));
    }

    /**
     * WAI-ARIA APG tree keyboard interaction
     * - Down/Up: next/previous visible node
     * - Right: expand a collapsed node, or move to the first child of an
     *   expanded node
     * - Left: collapse an expanded node, or move to the parent
     * - Home/End: first/last visible node
     * - Enter: follows the link (native)
     * @param {KeyboardEvent} e - Keydown event
     */
    async keydownHandler(e) {
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;

      const node = e.target.closest('.node');

      if (!node || !this.container.contains(node)) return;

      const item = this.treeitemOf(node);
      const items = () => this.visibleItems();
      const isRoot = node.classList.contains('root');
      const expanded = item.getAttribute('aria-expanded');

      switch (e.key) {
        case 'ArrowDown': {
          e.preventDefault();
          const list = items();
          const next = list[list.indexOf(item) + 1];
          if (next) this.setActiveItem(next, true);
          break;
        }
        case 'ArrowUp': {
          e.preventDefault();
          const list = items();
          const prev = list[list.indexOf(item) - 1];
          if (prev) this.setActiveItem(prev, true);
          break;
        }
        case 'ArrowRight': {
          e.preventDefault();
          if (expanded === 'false') {
            await this.setExpanded(node, true);
          } else if (expanded === 'true') {
            const firstChild = node.querySelector(
              ':scope > .node-children > li.node'
            );
            if (firstChild) {
              this.setActiveItem(this.treeitemOf(firstChild), true);
            }
          }
          break;
        }
        case 'ArrowLeft': {
          e.preventDefault();
          if (expanded === 'true' && !isRoot) {
            await this.setExpanded(node, false);
            this.setActiveItem(item, true);
          } else if (!isRoot) {
            const parent = node.parentElement.closest('.node');
            if (parent) this.setActiveItem(this.treeitemOf(parent), true);
          }
          break;
        }
        case 'Home': {
          e.preventDefault();
          this.setActiveItem(items()[0], true);
          break;
        }
        case 'End': {
          e.preventDefault();
          const list = items();
          this.setActiveItem(list[list.length - 1], true);
          break;
        }
        default:
          break;
      }
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
