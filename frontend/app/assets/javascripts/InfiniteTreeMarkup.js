//= require MixedContentHelper

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
   *     - `div.node-title-container` for the node's data
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
     * @param {Object} i18n - Internationalization strings
     */
    constructor(resourceUri, batchSize, i18n) {
      this.resourceUri = resourceUri;
      this.repoId = resourceUri.split('/')[2];
      this.resourceId = resourceUri.split('/')[4];
      this.BATCH_SIZE = batchSize;
      this.i18n = i18n;
    }

    /**
     * Creates a tree structure with a root node
     * @param {string} title - Display text for the root node
     * @returns {DocumentFragment} An <ol> with a single <li>
     */
    root(title) {
      const _title = new MixedContentHelper(title);
      const rootFrag = new DocumentFragment();
      const rootTemplate = document
        .querySelector('#infinite-tree-root-template')
        .content.cloneNode(true);
      const rootElement = rootTemplate.querySelector('li');
      const contentWrapper = rootTemplate.querySelector('.node-body');
      const link = rootTemplate.querySelector('.node-title');

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
     * Creates a list of empty placeholders for batches of children
     * @param {string} parentElementId - Value of the parent node's HTML id attribute
     * @param {number} level - Tree level of the children (0 for root)
     * @param {number} numBatches - Number of batch placeholders to create
     * @returns {DocumentFragment} - An <ol> with placeholder <li>s
     */
    list(parentElementId, level, numBatches) {
      const listFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-children-list-template')
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
      const nodeRecordId = data.uri.split('/')[4];
      const nodeElementId = `archival_object_${nodeRecordId}`;
      const title = new MixedContentHelper(this.title(data));
      const aHref = `#tree::${nodeElementId}`;
      const nodeFrag = new DocumentFragment();
      const nodeTemplate = document
        .querySelector('#infinite-tree-node-template')
        .content.cloneNode(true);
      const nodeElement = nodeTemplate.querySelector('li');
      const contentWrapper = nodeTemplate.querySelector('.node-body');
      const indentation = nodeTemplate.querySelector('.node-indentation');
      const link = nodeTemplate.querySelector('.node-title');

      nodeElement.id = nodeElementId;
      nodeElement.classList.add(`indent-level-${level}`);
      nodeElement.setAttribute('data-uri', data.uri);

      if (data.child_count > 0) {
        const totalBatches = Math.ceil(data.child_count / this.BATCH_SIZE);
        nodeElement.setAttribute('data-total-child-batches', totalBatches);
        nodeElement.setAttribute('data-has-expanded', 'false');
        nodeElement.setAttribute('aria-expanded', 'false');

        indentation.appendChild(this.expandButton(title.cleaned));
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

      contentWrapper.setAttribute('title', title.cleaned);

      if (data.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;

        nodeTemplate
          .querySelector('.node-title')
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
     * Creates an expand button to show and hide a node's children
     * @param {string} title - The node title
     * @returns {DocumentFragment} - A <button>
     */
    expandButton(title) {
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
     */
    title(node) {
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

  exports.InfiniteTreeMarkup = InfiniteTreeMarkup;
})(window);
