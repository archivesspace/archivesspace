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
      this.appUrlPrefix = appUrlPrefix;
      this.resourceUri = resourceUri;
      this.repoId = this.resourceUri.split('/')[2];
      this.resourceId = this.resourceUri.split('/')[4];
      this.baseUri = `${this.resourceUri}/tree`;
      // this.baseUri = `/resources/${this.resourceId}/tree`;
      this.rootUri = `${this.baseUri}/root`;
      this.nodeUri = `${this.baseUri}/node`;
      this.batchUri = `${this.baseUri}/waypoint`; // TODO: rename endpoint to /batch
      this.i18n = { sep: identifier_separator, bulk: date_type_bulk };

      this.container = document.querySelector('#infinite-tree-container');

      this.batchObserver = new IntersectionObserver(
        (entries, observer) => {
          this.batchObserverHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '-30% 0px -30% 0px',
          threshold: 0,
        }
      );

      this.renderRoot();
    }

    /**
     * Render the root node and its first batch of children
     */
    async renderRoot() {
      const rootData = await this.fetchRoot();
      const rootFrag = this.rootFrag(this.nodeTitle(rootData));
      const rootNode = rootFrag.querySelector('.root.node');

      await this.renderInitialChildren(rootNode, rootData);

      this.container.appendChild(rootFrag);
    }

    /**
     * Fetch the root data
     * @returns {Object} - Root data object returned from the server
     */
    async fetchRoot() {
      try {
        const response = await fetch(this.appUrlPrefix + this.rootUri);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Provide a DocumentFragment of the root tree list
     * @param {string} title - Title of the root node
     * @returns {DocumentFragment} - DocumentFragment containing the root tree list
     */
    rootFrag(title) {
      const _title = new MixedContent(title);
      const rootFrag = new DocumentFragment();
      const rootTemplate = document
        .querySelector('#infinite-tree-root-template')
        .content.cloneNode(true);
      const rootElement = rootTemplate.querySelector('li');
      const contentWrapper = rootTemplate.querySelector('.node-content');
      const link = rootTemplate.querySelector('.title');

      rootElement.id = `resource_${this.resourceId}`;
      rootElement.setAttribute('data-uri', this.resourceUri);
      rootElement.setAttribute('aria-expanded', 'true');
      contentWrapper.setAttribute('title', _title.cleaned);
      link.href = `#tree::resource_${this.resourceId}`;
      if (_title.isMixed) {
        link.innerHTML = _title.input;
      } else {
        link.textContent = _title.cleaned;
      }

      rootFrag.appendChild(rootTemplate);

      return rootFrag;
    }

    /**
     * Provide a DocumentFragment of a list of child batch placeholders
     * @param {string} parentElementId - Value of the parent node's HTML id attribute
     * @param {number} level - Tree level of the children
     * @param {number} numBatches - Number of batches to create
     * @returns {DocumentFragment} - DocumentFragment of the list of child batch placeholders
     */
    childrenListFrag(parentElementId, level, numBatches) {
      const childrenFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-children-list-template')
        .content.cloneNode(true);
      const listElement = listTemplate.querySelector('ol');

      listElement.setAttribute('data-parent-id', parentElementId);
      listElement.setAttribute('data-tree-level', level);
      listElement.setAttribute('data-total-child-batches', numBatches);

      for (let i = 0; i < numBatches; i++) {
        const itemTemplate = document
          .querySelector('#infinite-tree-children-batch-placeholder-template')
          .content.cloneNode(true);
        const itemElement = itemTemplate.querySelector('li');

        itemElement.setAttribute('data-batch-placeholder', i);

        listElement.appendChild(itemElement);
      }

      childrenFrag.appendChild(listTemplate);

      return childrenFrag;
    }

    /**
     * Render the first batch of a node's children, observe to fetch
     * any remaining batches of children
     * @param {HTMLElement} nodeEl - The node element to initialize children for
     * @param {Object} nodeData - The node data object from the server
     */
    async renderInitialChildren(nodeEl, nodeData) {
      const isRoot = nodeEl.classList.contains('root');
      const wpKey = isRoot ? '' : nodeData.uri;
      let level;

      if (isRoot) {
        level = 0;
      } else {
        level = Number(
          nodeEl.closest('.children').getAttribute('data-tree-level')
        );
      }

      const childrenListFrag = this.childrenListFrag(
        nodeEl.id,
        level + 1,
        nodeData.waypoints
      );

      nodeEl.appendChild(childrenListFrag);

      this.renderBatchOfChildren(
        nodeEl.querySelector(`.children`),
        nodeData.precomputed_waypoints[wpKey][0],
        nodeData.waypoints > 1,
        0
      );
    }

    /**
     * Fetch the tree of the node with the given id
     * @param {number} nodeId - ID of the node, ie: 18028
     * @returns {Object} - Node object as returned from the server
     */
    async fetchNode(nodeId) {
      const query = new URLSearchParams();

      query.append(
        'node',
        `/repositories/${this.repoId}/archival_objects/${nodeId}`
      );

      try {
        const response = await fetch(`${this.nodeUri}?${query}`);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Fetch a batch of the given node's children
     * @param {Object} params - Object of params for the ajax call with the signature:
     * @param {string} params.node - Node URL param in the form of '' or
     * '/repositories/X/archival_objects/Y'
     * @param {number} params.offset - Offset URL param
     * @returns {array} - Array of batch objects as returned from the server
     */
    async fetchBatch(params) {
      const query = new URLSearchParams();

      for (const key in params) {
        query.append(key, params[key]);
      }

      try {
        const response = await fetch(`${this.batchUri}?${query}`);
        const batch = await response.json();

        return batch;
      } catch (err) {
        console.error('Error fetching batch:', err);

        return null;
      }
    }

    /**
     * Provide the DocumentFragment for a node list item
     * @param {Object} data - Node data object from the server
     * @param {number} level - Tree level of the node
     * @param {boolean} shouldObserve - Whether or not to observe the node
     * in order to populate a next empty batch
     * @param {number} [parentId=null] - Optional ID of the node's parent; if null
     * then parent is assumed to be the root resource
     * @param {number} [offset=null] - Optional offset of the next batch to
     * populate; required if `shouldObserve` is true
     * @returns {DocumentFragment} - DocumentFragment containing the node list item
     */
    nodeFrag(data, level, shouldObserve, parentId = null, offset = null) {
      const nodeRecordId = data.uri.split('/')[4];
      const nodeElementId = `archival_object_${nodeRecordId}`;
      const title = new MixedContent(this.nodeTitle(data));
      const aHref = `#tree::${nodeElementId}`;
      const nodeFrag = new DocumentFragment();
      const nodeTemplate = document
        .querySelector('#infinite-tree-node-template')
        .content.cloneNode(true);
      const nodeElement = nodeTemplate.querySelector('li');
      const contentWrapper = nodeTemplate.querySelector('.node-content');
      const link = nodeTemplate.querySelector('.title');

      nodeElement.id = nodeElementId;
      nodeElement.classList.add(`indent-level-${level}`);
      nodeElement.setAttribute('data-uri', data.uri);

      if (data.child_count > 0) {
        const totalBatches = Math.ceil(
          data.child_count / this.CHILDREN_BATCH_SIZE
        );

        nodeElement.setAttribute('data-total-child-batches', totalBatches);
        nodeElement.setAttribute('data-has-expanded', 'false');
        nodeElement.setAttribute('aria-expanded', 'false');
      } else if (data.child_count == 0) {
        nodeTemplate.querySelector('.expandme').style.visibility = 'hidden';
        nodeTemplate
          .querySelector('.expandme')
          .setAttribute('aria-hidden', 'true');
      }

      if (shouldObserve) {
        let parentUri = '';

        if (parentId) {
          if (parentId.startsWith('resource')) {
            parentUri = '';
          } else if (parentId.startsWith('archival_object')) {
            const parentNodeId = parentId.split('_')[2];
            parentUri = `/repositories/${this.repoId}/archival_objects/${parentNodeId}`;
          }
        }

        nodeElement.setAttribute('data-observe-next-batch', 'true');
        nodeElement.setAttribute('data-observe-node', parentUri);
        nodeElement.setAttribute('data-observe-offset', offset);
      }

      contentWrapper.setAttribute('title', title.cleaned);
      nodeTemplate.querySelector('.sr-only').textContent = title.cleaned;

      if (data.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;
        nodeTemplate
          .querySelector('.record-title')
          .insertAdjacentHTML('beforebegin', iconHtml);
      }

      link.setAttribute('href', aHref);
      if (title.isMixed) {
        link.innerHTML = title.input;
      } else {
        link.textContent = title.cleaned;
      }

      nodeFrag.appendChild(nodeTemplate);

      return nodeFrag;
    }

    /**
     * Populate a child list with a batch of child nodes
     * @param {HTMLElement} list - The child list to populate
     * @param {array} nodes - Node objects to populate the list with
     * @param {boolean} hasNextBatch - Whether or not there is a next batch
     * @param {number} batchNumber - The batch number of nodes being populated
     */
    renderBatchOfChildren(list, nodes, hasNextBatch, batchNumber = 0) {
      if (!Array.isArray(nodes)) {
        console.error('Expected nodes to be an array, got:', nodes);
        return;
      }

      if (!list) {
        console.error('List element is null or undefined');
        return;
      }

      const parentId = list.getAttribute('data-parent-id');

      if (!parentId) {
        console.error('List element is missing data-parent-id attribute');
        return;
      }

      const level = Number(list.getAttribute('data-tree-level'));

      if (!level) {
        console.error('List element is missing data-tree-level attribute');
        return;
      }

      const batchFrag = new DocumentFragment();

      nodes.forEach((node, i) => {
        const observeThisNode =
          i == Math.floor(this.CHILDREN_BATCH_SIZE / 2) - 1 && hasNextBatch;
        const markupArgs = [node, level, observeThisNode];

        if (observeThisNode) {
          markupArgs.push(parentId, batchNumber + 1);
        }

        batchFrag.appendChild(this.nodeFrag(...markupArgs));
      });

      const placeholder = list.querySelector(
        `li[data-batch-placeholder="${batchNumber}"]`
      );

      if (!placeholder) {
        console.error('Could not find placeholder for batch:', {
          batchNumber,
          parentId,
          listHTML: list.innerHTML,
          placeholderSelector: `li[data-batch-placeholder="${batchNumber}"]`,
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
          debugger;
          const batchData = await this.fetchBatch({
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
        const nodeData = await this.fetchNode(Number(nodeRecordId));
        await this.renderInitialChildren(node, nodeData);
        node.setAttribute('data-has-expanded', 'true');
      }

      node.setAttribute('aria-expanded', isExpanding ? 'true' : 'false');
      icon.classList.toggle('expanded');
    }

    /**
     * Build the title of a node
     * @param {Object} node - Node data
     * @returns {string} - Title of the node
     */
    nodeTitle(node) {
      const title = [];

      if (SHOW_IDENTIFIERS_IN_TREE && node.identifier && node.parsed_title) {
        title.push(`${node.identifier}${this.i18n.sep} ${node.parsed_title}`);
      } else if (node.parsed_title) {
        title.push(node.parsed_title);
      }

      if (node.label) {
        title.push(node.label);
      }

      if (node.dates && node.dates.length > 0) {
        node.dates.forEach(date => {
          if (date.expression) {
            if (date.type === 'bulk') {
              title.push(`${this.i18n.bulk}: ${date.expression}`);
            } else {
              title.push(date.expression);
            }
          } else if (date.begin && date.end) {
            if (date.type === 'bulk') {
              title.push(`${this.i18n.bulk}: ${date.begin}-${date.end}`);
            } else {
              title.push(`${date.begin}-${date.end}`);
            }
          } else if (date.begin) {
            if (date.type === 'bulk') {
              title.push(`${this.i18n.bulk}: ${date.begin}`);
            } else {
              title.push(date.begin);
            }
          }
        });
      }

      return title.join(', ');
    }
  }

  exports.InfiniteTree = InfiniteTree;
})(window);
