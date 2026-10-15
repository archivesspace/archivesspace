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
   *     - an `::after` pseudo-element to indicate the current node
   * All nodes with children have a nested ordered list, `ol.node-children`, as the
   * next sibling of `.node-row`, containing each child as `li.node`.
   * Accessibility follows the normal Tab order/disclosure pattern.
   */

  /**
   * Title rule sets. Each page keeps the titles it showed before the
   * LargeTree → InfiniteTree migration.
   * - 'collection-organization': the original InfiniteTree rules, applied to
   *   every node including the root
   * - 'record': the legacy LargeTree `SimpleRenderer` rules used by record
   *   show-page sidebars and classification search subgroups
   */
  const TITLE_RULES = ['collection-organization', 'record'];

  class InfiniteTreeMarkup {
    /**
     * @constructor
     * @param {Object} options
     * @param {string} options.rootUri - The URI of the tree root
     * @param {number} options.batchSize - The number of child nodes per batch
     * @param {Object} options.i18n - Internationalization strings
     * @param {string} options.i18n.sep - Resource identifier separator
     * @param {string} [options.i18n.classificationSep] - Classification identifier separator
     * @param {string} options.i18n.bulk - Bulk date label
     * @param {string} [options.i18n.expand] - Expand button label
     * @param {string} [options.i18n.collapse] - Collapse button label
     * @param {string} options.titleRules - One of TITLE_RULES
     * @param {function(Object): string} [options.linkFor] - Returns the href
     * for a node's title link given its data; defaults to a `#tree::` hash
     */
    constructor({ rootUri, batchSize, i18n, titleRules, linkFor }) {
      const root = InfiniteTreeIds.parseUri(rootUri);

      this.rootUri = rootUri;
      this.repoId = root.repoId;
      this.rootElementId = InfiniteTreeIds.uriToElementId(rootUri);
      this.BATCH_SIZE = batchSize;
      this.i18n = i18n;
      if (!TITLE_RULES.includes(titleRules)) {
        throw new Error(`Unknown InfiniteTree titleRules: ${titleRules}`);
      }

      this.titleRules = titleRules;
      this.linkFor =
        linkFor || (data => InfiniteTreeIds.uriToLocationHash(data.uri));
    }

    /**
     * Clones the content of a template by id
     * @param {string} id - The template's HTML id
     * @returns {DocumentFragment} - The cloned template content
     */
    #template(id) {
      return document.querySelector(`#${id}`).content.cloneNode(true);
    }

    /**
     * Sets a title link's href and text, and the row's tooltip.
     *
     * `parsed_title` arrives HTML-escaped and sanitized by the backend's
     * MixedContentParser. Record trees insert it as HTML, as LargeTree's
     * SimpleRenderer did, so entities like `&amp;` render correctly.
     * Collection organization keeps its original behavior: HTML only when the
     * title contains mixed-content markup.
     * @param {HTMLAnchorElement} link - The link
     * @param {HTMLElement} contentWrapper - The node's `.node-body`
     * @param {Object} data - Node data from the server
     * @param {MixedContentHelper} title - The processed title
     */
    #fillLink(link, contentWrapper, data, title) {
      link.setAttribute('href', this.linkFor(data));

      if (this.titleRules === 'record') {
        link.innerHTML = title.input;
        contentWrapper.setAttribute('title', link.textContent);
        return;
      }

      if (title.isMixed) {
        link.innerHTML = title.input;
      } else {
        link.textContent = title.cleaned;
      }

      contentWrapper.setAttribute('title', title.cleaned);
    }

    /**
     * Creates a root list element
     * @returns {DocumentFragment} - The root <ol> element
     */
    rootList() {
      const listFrag = new DocumentFragment();

      listFrag.appendChild(this.#template('infinite-tree-root-list-template'));

      return listFrag;
    }

    /**
     * Creates a root node element
     * @param {Object} data - Root data object from the server
     * @returns {DocumentFragment} - The root <li> element
     */
    rootNode(data) {
      const title = new MixedContentHelper(this.title(data, true));
      const rootFrag = new DocumentFragment();
      const rootTemplate = this.#template('infinite-tree-root-node-template');
      const rootElement = rootTemplate.querySelector('li');
      const contentWrapper = rootTemplate.querySelector('.node-body');
      const link = rootTemplate.querySelector('.node-title');

      rootElement.id = this.rootElementId;
      rootElement.setAttribute('data-uri', this.rootUri);

      this.#fillLink(link, contentWrapper, data, title);

      rootFrag.appendChild(rootTemplate);

      return rootFrag;
    }

    /**
     * Creates a list of empty placeholders for batches of children
     * @param {string} parentElementId - Value of the parent node's HTML id attribute
     * @param {number} level - The tree level (root is 0)
     * @param {number} numBatches - Number of batch placeholder list items to create
     * @returns {DocumentFragment} - An <ol> element with appropriate attributes and batch placeholder <li>s
     */
    nodeList(parentElementId, level, numBatches) {
      const listFrag = new DocumentFragment();
      const listTemplate = this.#template('infinite-tree-node-list-template');
      const listElement = listTemplate.querySelector('ol');
      const listElementId = `${parentElementId}-children`;

      listElement.id = listElementId;
      listElement.setAttribute('data-parent-id', parentElementId);
      listElement.setAttribute('data-tree-level', level);
      listElement.setAttribute('data-total-child-batches', numBatches);

      for (let i = 0; i < numBatches; i++) {
        const itemTemplate = this.#template(
          'infinite-tree-batch-placeholder-template'
        );
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
     * @param {string} [parentId=null] - Optional HTML id of the node's parent;
     * required if `shouldObserve` is true
     * @param {number} [offset=null] - Optional offset of the next batch to
     * populate; required if `shouldObserve` is true
     * @returns {DocumentFragment} - A <li>
     */
    node(data, level, shouldObserve, parentId = null, offset = null) {
      const nodeElementId = InfiniteTreeIds.uriToElementId(data.uri);
      const title = new MixedContentHelper(this.title(data));
      const nodeFrag = new DocumentFragment();
      const nodeTemplate = this.#template('infinite-tree-node-template');
      const nodeElement = nodeTemplate.querySelector('li');
      const contentWrapper = nodeTemplate.querySelector('.node-body');
      const indentation = nodeTemplate.querySelector('.node-indentation');
      const link = nodeTemplate.querySelector('.node-title');
      const hasChildren = data.child_count > 0;
      const childListId = hasChildren ? `${nodeElementId}-children` : null;

      nodeElement.id = nodeElementId;
      nodeElement.classList.add(`indent-level-${level}`);
      nodeElement.setAttribute('data-uri', data.uri);

      if (hasChildren) {
        const totalBatches = Math.ceil(data.child_count / this.BATCH_SIZE);

        nodeElement.setAttribute('data-total-child-batches', totalBatches);
        nodeElement.setAttribute('data-is-expanded', 'false');
      }

      if (shouldObserve) {
        const parentUri = parentId
          ? InfiniteTreeIds.elementIdToParentRef(parentId, this.repoId)
          : '';

        nodeElement.setAttribute('data-observe-next-batch', 'true');
        nodeElement.setAttribute('data-parent-uri', parentUri);
        nodeElement.setAttribute('data-observe-offset', offset);
      }

      if (data.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;

        link.insertAdjacentHTML('beforebegin', iconHtml);
      }

      this.#fillLink(link, contentWrapper, data, title);

      if (hasChildren) {
        // Label from the rendered link text so entities are decoded
        indentation.appendChild(
          this.expandButton(link.textContent, childListId)
        );
      }

      nodeFrag.appendChild(nodeTemplate);

      return nodeFrag;
    }

    /**
     * Creates a native disclosure button that shows/hides a node's children.
     * It holds two visually hidden labels, "Expand {title}" and "Collapse {title}",
     * managed by CSS. Its state is also exposed as `aria-expanded`.
     * @param {string} title - The node title as plain text
     * @param {string} childListId - The HTML id of the children container this button controls
     * @returns {DocumentFragment} - A <button>
     */
    expandButton(title, childListId) {
      const btnFrag = new DocumentFragment();
      const btnTemplate = this.#template(
        'infinite-tree-expand-button-template'
      );
      const btn = btnTemplate.querySelector('.node-expand');
      const expandLabel = btn.querySelector(
        '.node-expand-label[data-when="collapsed"]'
      );
      const collapseLabel = btn.querySelector(
        '.node-expand-label[data-when="expanded"]'
      );

      expandLabel.textContent = this.i18n.expand.replace(
        '%{title}',
        () => title
      );
      collapseLabel.textContent = this.i18n.collapse.replace(
        '%{title}',
        () => title
      );

      btn.setAttribute('aria-controls', childListId);

      btnFrag.appendChild(btnTemplate);

      return btnFrag;
    }

    /**
     * Builds the title of a node according to `this.titleRules`
     * @param {Object} node - Node data
     * @param {boolean} [isRoot=false] - Whether the node is the tree root
     * @returns {string} - Title of the node
     *
     * @todo Migrate this logic to the server if possible
     */
    title(node, isRoot = false) {
      if (this.titleRules === 'record') {
        return isRoot
          ? this.#recordRootTitle(node)
          : this.#recordNodeTitle(node);
      }

      return this.#fullTitle(node);
    }

    /**
     * Prefixes a title with an identifier and separator
     * @param {string|undefined} identifier - The identifier
     * @param {string} sep - The separator
     * @param {string} title - The title
     * @returns {string} - eg 'ID: Title'
     */
    #withIdentifier(identifier, sep, title) {
      return identifier ? `${identifier}${sep} ${title}` : title;
    }

    /**
     * Legacy LargeTree (`SimpleRenderer`) root title: identifier prefix for
     * classifications always, for resources when configured; no label/dates
     * @param {Object} node - Root data
     * @returns {string} - Title
     */
    #recordRootTitle(node) {
      const title = node.parsed_title || '';

      if (node.jsonmodel_type === 'classification') {
        return this.#withIdentifier(
          node.identifier,
          this.i18n.classificationSep,
          title
        );
      }

      if (node.jsonmodel_type === 'resource' && SHOW_IDENTIFIERS_IN_TREE) {
        return this.#withIdentifier(node.identifier, this.i18n.sep, title);
      }

      return title;
    }

    /**
     * Legacy LargeTree (`SimpleRenderer`) node title: classification terms
     * always get their identifier and no label/dates; everything else uses
     * the full title rules
     * @param {Object} node - Node data
     * @returns {string} - Title
     */
    #recordNodeTitle(node) {
      if (node.jsonmodel_type === 'classification_term') {
        return this.#withIdentifier(
          node.identifier,
          this.i18n.classificationSep,
          node.parsed_title || ''
        );
      }

      return this.#fullTitle(node);
    }

    /**
     * Identifier (when configured), title, label, and dates
     * @param {Object} node - Node data
     * @returns {string} - Title
     */
    #fullTitle(node) {
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
