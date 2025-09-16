//= require MixedContentHelper
//= require InfiniteTreeI18n

(function (exports) {
  /**
   * A tree is an ordered list, represented in the DOM as `ol.infinite-tree`.
   * The tree has exactly one list item which is the root node.
   * The root node has zero or more child nodes,
   * each of which have zero or more child nodes,
   * each of which have zero or more child nodes, etc.
   * All nodes in the DOM are represented as `li.node`; the root as `li.root.node`.
   * All nodes have `div.node-row` used for absolute positioning its data and
   * allowing full-width highlighting of the current node, and containing:
   *   - `div.node-body` a layout wrapper containing:
   *     - `div.node-indentation` for tree level visualization via a repeating
   *       gradient and padding, and expand/collapse button if children
   *     - `div.node-column[data-column]`s for the node's data
   *     - an `::after` pseudo-element to indicate the currently selected node
   *       via the "current" InfiniteRecords record
   * All nodes with children have a nested ordered list, `ol.node-children`, as the
   * next sibling of `.node-row`, containing each child as `li.node`.
   */

  class InfiniteTreeMarkup {
    /**
     * @constructor
     * @param {string} resourceUri - The URI of the collection resource
     * @param {number} batchSize - The number of child nodes per batch
     * @param {Object} i18n - The i18n object
     * @param {string} i18n.sep - The identifier separator
     * @param {string} i18n.bulk - The date type bulk
     * @param {Object} i18n.enumerations - The enumeration translations object
     */
    constructor(resourceUri, batchSize, i18n) {
      this.resourceUri = resourceUri;
      this.repoId = resourceUri.split('/')[2];
      this.resourceId = resourceUri.split('/')[4];
      this.BATCH_SIZE = batchSize;
      this.i18n = new InfiniteTreeI18n(i18n);
    }

    /**
     * Creates a root list element
     * @returns {DocumentFragment} - The root <ol> element
     */
    rootList() {
      const listFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-root-list-template')
        .content.cloneNode(true);

      listFrag.appendChild(listTemplate);

      return listFrag;
    }

    /**
     * Creates a root node element
     * @param {Object} data - Root data object fetched from server
     * @returns {DocumentFragment} - The root <li> element
     */
    rootNode(data) {
      const rootFrag = new DocumentFragment();
      const rootTemplate = document
        .querySelector('#infinite-tree-root-node-template')
        .content.cloneNode(true);
      const rootElement = rootTemplate.querySelector('li');
      const rootBody = rootTemplate.querySelector('.node-body');

      this.#setRootMetadata(rootElement, data);

      this.#populateNodeBody(rootBody, data);

      rootFrag.appendChild(rootTemplate);

      return rootFrag;
    }

    /**
     * Creates a list of empty placeholders for batches of children
     * @param {string} parentElementId - Value of the parent node's HTML id attribute
     * @param {number} level - Tree level of the children (0 for root)
     * @param {number} numBatches - Number of batch placeholder list items to create
     * @returns {DocumentFragment} - An <ol> element with appropriate attributes and batch placeholder <li>s
     */
    nodeList(parentElementId, level, numBatches) {
      const listFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-node-list-template')
        .content.cloneNode(true);
      const listElement = listTemplate.querySelector('ol');

      listElement.setAttribute('data-parent-id', parentElementId);
      listElement.setAttribute('data-tree-level', level);
      listElement.setAttribute('data-total-child-batches', numBatches);

      for (let i = 0; i < numBatches; i++) {
        const itemTemplate = document
          .querySelector('#infinite-tree-batch-placeholder-template')
          .content.cloneNode(true);
        const itemElement = itemTemplate.querySelector('li');

        itemElement.setAttribute('data-batch-placeholder', i);

        listElement.appendChild(itemElement);
      }

      listFrag.appendChild(listTemplate);

      return listFrag;
    }

    /**
     * Creates a node
     * @param {Object} data - Node data object from the server
     * @param {number} level - Tree level of the node (0 for root)
     * @param {boolean} shouldObserve - Whether or not to observe the node
     * in order to populate a next empty batch
     * @param {number} [parentId=null] - Optional ID of the node's parent; if null
     * then parent is assumed to be the root resource
     * @param {number} [offset=null] - Optional offset of the next batch to
     * populate; required if `shouldObserve` is true
     * @returns {DocumentFragment} - A <li>
     */
    node(data, level, shouldObserve, parentId = null, offset = null) {
      const nodeFrag = new DocumentFragment();
      const nodeTemplate = document
        .querySelector('#infinite-tree-node-template')
        .content.cloneNode(true);
      const nodeElement = nodeTemplate.querySelector('li');
      const nodeBody = nodeTemplate.querySelector('.node-body');

      this.#setNodeMetadata(
        nodeElement,
        data,
        level,
        shouldObserve,
        parentId,
        offset
      );

      this.#populateNodeBody(nodeBody, data);

      nodeFrag.appendChild(nodeTemplate);

      return nodeFrag;
    }

    /**
     * Creates a standalone node body for refreshing existing nodes
     * @param {Object} data - Node data object from the server
     * @param {string} uri - The URI of the node being refreshed
     * @param {HTMLElement} [currentNode] - The current node element to preserve expansion state
     * @returns {DocumentFragment} - A DocumentFragment containing the populated .node-body
     */
    nodeBody(data, uri, currentNode = null) {
      // Determine which template to use based on URI
      const parts = InfiniteTreeIds.uriToParts(uri);
      const isRoot = parts.type === 'resource';

      // Get the appropriate template
      const templateId = isRoot
        ? '#infinite-tree-root-node-template'
        : '#infinite-tree-node-template';

      const template = document
        .querySelector(templateId)
        .content.cloneNode(true);
      const nodeBody = template.querySelector('.node-body');

      // Use the existing populateNodeBody method to fill in all content
      this.#populateNodeBody(nodeBody, data);

      // If we have a current node and this node has children, preserve expansion state
      if (currentNode && data.child_count > 0) {
        const isExpanded = currentNode.getAttribute('aria-expanded') === 'true';
        const newExpandIcon = nodeBody.querySelector('.node-expand-icon');

        if (newExpandIcon && isExpanded) {
          newExpandIcon.classList.add('expanded');
        }
      }

      const fragment = new DocumentFragment();

      fragment.appendChild(nodeBody);

      return fragment;
    }

    /**
     * Sets the metadata on the root node element
     * @param {Element} rootElement - The root <li> element
     * @param {Object} data - The root data object
     * @private
     */
    #setRootMetadata(rootElement, data) {
      rootElement.id = `resource_${this.resourceId}`;
      rootElement.setAttribute('data-uri', this.resourceUri);
      rootElement.setAttribute('title', this.#titleHelper(data).cleaned);

      if (data.child_count > 0)
        rootElement.setAttribute('aria-expanded', 'true');
    }

    /**
     * Sets the metadata on non root node elements
     * @param {Element} nodeElement - The node <li> element
     * @param {Object} data - The node data object
     * @param {number} level - Tree level of the node (0 for root)
     * @param {boolean} shouldObserve - Whether or not to observe the node
     * in order to populate a next empty batch
     * @param {number} [parentId=null] - Optional ID of the node's parent; if null
     * then parent is assumed to be the root resource
     * @param {number} [offset=null] - Optional offset of the next batch to
     * populate; required if `shouldObserve` is true
     * @private
     */
    #setNodeMetadata(
      nodeElement,
      data,
      level,
      shouldObserve,
      parentId = null,
      offset = null
    ) {
      const uriParts = InfiniteTreeIds.uriToParts(data.uri);
      const nodeElementId = `${uriParts.type}_${uriParts.id}`;

      nodeElement.id = nodeElementId;
      nodeElement.classList.add(`indent-level-${level}`);
      nodeElement.setAttribute('data-uri', data.uri);

      if (data.child_count > 0) {
        const totalBatches = Math.ceil(data.child_count / this.BATCH_SIZE);
        nodeElement.setAttribute('data-total-child-batches', totalBatches);
        nodeElement.setAttribute('data-has-expanded', 'false');
        nodeElement.setAttribute('aria-expanded', 'false');
      }

      if (shouldObserve) {
        let parentUri;

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
    }

    /**
     * Populates the .node-body content for root and non root nodes
     * @param {Element} bodyEl - The node body <div> element
     * @param {Object} data - The node data object
     * @private
     */
    #populateNodeBody(bodyEl, data) {
      const titleCleaned = this.#titleHelper(data).cleaned;
      const indentationEl = bodyEl.querySelector('.node-indentation');

      bodyEl.setAttribute('title', titleCleaned);

      if (indentationEl && data.child_count > 0) {
        indentationEl.appendChild(this.#expandButton(titleCleaned));
      }

      if (data.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;

        bodyEl
          .querySelector('.record-title')
          .insertAdjacentHTML('beforebegin', iconHtml);
      }

      this.#processColumns(bodyEl.querySelectorAll('.node-column'), data);
    }

    /**
     * Builds a title helper object for a node
     * @param {Object} data - The node data object
     * @returns {MixedContentHelper} - The title helper object
     * @private
     */
    #titleHelper(data) {
      return new MixedContentHelper(this.#buildTitle(data));
    }

    /**
     * Processes columns for root and non root node elements
     * @param {NodeList} columns - The column elements to process
     * @param {Object} data - The node data object
     * @private
     */
    #processColumns(columns, data) {
      columns.forEach(column => {
        const colName = column.dataset.column;

        switch (colName) {
          case 'title': {
            const uriParts = InfiniteTreeIds.uriToParts(data.uri);
            const href = `#tree::${uriParts.type}_${uriParts.id}`;
            const titleHelper = this.#titleHelper(data);

            const titleEl = column.querySelector('.record-title');

            titleEl.href = href;
            titleEl.setAttribute('title', titleHelper.cleaned);

            if (titleHelper.isMixed) {
              titleEl.innerHTML = titleHelper.input;
            } else {
              titleEl.textContent = titleHelper.cleaned;
            }

            if (data.suppressed) {
              const suppressedBadge = document
                .querySelector('#infinite-tree-suppressed-template')
                .content.cloneNode(true);
              titleEl.prepend(suppressedBadge);
            }
            break;
          }

          case 'level': {
            const levelText = this.i18n.t('archival_record_level', data.level);
            column.textContent = levelText;
            column.title = levelText;
            break;
          }

          case 'type': {
            const typeText = this.#buildTypeSummary(data);
            column.textContent = typeText;
            column.title = typeText;
            break;
          }

          case 'container': {
            const containerText = this.#buildContainerSummary(data);
            column.textContent = containerText;
            column.title = containerText;
            break;
          }

          case 'identifier': {
            if (data.identifier) {
              column.textContent = data.identifier;
              column.title = data.identifier;
            }
            break;
          }
        }
      });
    }

    /**
     * Creates an expand button to show and hide a node's children
     * @param {string} title - The node title
     * @returns {DocumentFragment} - A <button>
     * @private
     */
    #expandButton(title) {
      const btnFrag = new DocumentFragment();
      const btnTemplate = document
        .querySelector('#infinite-tree-expand-button-template')
        .content.cloneNode(true);
      const btn = btnTemplate.querySelector('.node-expand');

      btn.querySelector('.sr-only').textContent = title;

      btnFrag.appendChild(btnTemplate);

      return btnFrag;
    }

    /**
     * Builds the title of a node
     * @param {Object} node - Node data
     * @returns {string} - Title of the node
     *
     * @todo Migrate this logic to the server if possible
     * @private
     */
    #buildTitle(node) {
      const title = [];

      if (node.parsed_title) {
        title.push(node.parsed_title);
      } else if (node.title) {
        title.push(node.title);
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

    /**
     * Builds a summary of the types for a node
     * @param {Object} node - Node data
     * @returns {string} - Type summary
     * @private
     */
    #buildTypeSummary(node) {
      let typeSummary = '';

      if (node.containers) {
        const types = [];

        node.containers.forEach(container => {
          types.push(
            this.i18n.t('instance_instance_type', container.instance_type)
          );
        });

        typeSummary = types.join(', ');
      }

      return typeSummary;
    }

    /**
     * Builds a summary of the containers for a node
     * @param {Object} node - Node data
     * @returns {string} - Container summary
     * @private
     */
    #buildContainerSummary(node) {
      let containerSummary = '';

      if (node.containers) {
        const containerSummaries = [];

        node.containers.forEach(container => {
          const summaryItems = [];

          if (container.top_container_indicator) {
            let topContainerSummary = '';

            if (container.top_container_type) {
              topContainerSummary +=
                this.i18n.t('container_type', container.top_container_type) +
                ': ';
            }

            topContainerSummary += container.top_container_indicator;

            if (container.top_container_barcode) {
              topContainerSummary +=
                ' [' + container.top_container_barcode + ']';
            }

            summaryItems.push(topContainerSummary);
          }

          if (container.type_2) {
            summaryItems.push(
              this.i18n.t('container_type', container.type_2) +
                ': ' +
                container.indicator_2
            );
          }

          if (container.type_3) {
            summaryItems.push(
              this.i18n.t('container_type', container.type_3) +
                ': ' +
                container.indicator_3
            );
          }

          if (summaryItems.length > 0) {
            containerSummaries.push(summaryItems.join(', '));
          }
        });

        containerSummary = containerSummaries.join('; ');
      }

      return containerSummary;
    }
  }

  exports.InfiniteTreeMarkup = InfiniteTreeMarkup;
})(window);
