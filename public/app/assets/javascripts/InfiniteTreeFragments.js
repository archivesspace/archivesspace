(function (exports) {
  class InfiniteTreeFragments {
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
     * Provide a DocumentFragment of the root tree list
     * @param {string} title - Title of the root node
     * @returns {DocumentFragment} - DocumentFragment containing the root tree list
     */
    root(title) {
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
     * Provide a DocumentFragment of an ordered list containing child batch placeholders
     * @param {string} parentElementId - Value of the parent node's HTML id attribute
     * @param {number} level - Tree level of the children
     * @param {number} numBatches - Number of batches to create
     * @returns {DocumentFragment} - DocumentFragment of the ordered list of child batch placeholders
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
          .querySelector('#infinite-tree-children-batch-placeholder-template')
          .content.cloneNode(true);
        const itemElement = itemTemplate.querySelector('li');

        itemElement.setAttribute('data-batch-placeholder', i);

        listElement.appendChild(itemElement);
      }

      listFrag.appendChild(listTemplate);

      return listFrag;
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
    node(data, level, shouldObserve, parentId = null, offset = null) {
      const nodeRecordId = data.uri.split('/')[4];
      const nodeElementId = `archival_object_${nodeRecordId}`;
      const title = new MixedContent(this.buildNodeTitle(data));
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
        const totalBatches = Math.ceil(data.child_count / this.BATCH_SIZE);

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
     * Build the title of a node
     * @param {Object} node - Node data
     * @returns {string} - Title of the node
     */
    // TODO: Migrate this logic to the server so it is available via the server data
    // instead of burdening the client with it
    buildNodeTitle(node) {
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

  exports.InfiniteTreeFragments = InfiniteTreeFragments;
})(window);
