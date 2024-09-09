(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {number} waypointSize - The number of nodes per waypoint
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     * @param {string} identifier_separator - The i18n identifier separator
     * @param {string} date_type_bulk - The i18n date type bulk
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(
      waypointSize,
      appUrlPrefix,
      resourceUri,
      identifier_separator,
      date_type_bulk
    ) {
      this.WAYPOINT_SIZE = waypointSize;
      this.appUrlPrefix = appUrlPrefix;
      this.resourceUri = resourceUri;
      this.repoId = this.resourceUri.split('/')[2];
      this.resourceId = this.resourceUri.split('/')[4];
      this.baseUri = `${this.resourceUri}/tree`;
      this.rootUri = `${this.baseUri}/root`;
      this.nodeUri = `${this.baseUri}/node`;
      this.waypointUri = `${this.baseUri}/waypoint`;
      this.i18n = { sep: identifier_separator, bulk: date_type_bulk };

      this.container = document.querySelector('#infinite-tree-container');

      this.waypointObserver = new IntersectionObserver(
        // Wrap handler in arrow fn to preserve `this` context
        (entries, observer) => {
          this.waypointScrollHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '-30% 0px -30% 0px',
        }
      );

      this.initTree();
    }

    /**
     * Initialize the large tree navigation sidebar with the collection's
     * root node and the first waypoint of its immediate children
     */
    async initTree() {
      const rootNode = await this.fetchRootNode();
      const rootNodeDivId = `resource_${this.resourceId}`;
      const firstWPData = rootNode.precomputed_waypoints[''][0];

      const tableRootFrag = new DocumentFragment();

      const tableRoot = document.createElement('div');
      tableRoot.setAttribute('role', 'list');
      tableRoot.className = 'table root';

      tableRoot.appendChild(this.rootRowMarkup(this.nodeTitle(rootNode)));
      tableRoot.appendChild(
        this.rootNodeWaypointsScaffold(rootNodeDivId, 1, rootNode.waypoints)
      );

      this.populateWaypoint(
        tableRoot.querySelector('.table-row-group'),
        firstWPData,
        1,
        rootNode.waypoints > 1
      );

      tableRootFrag.appendChild(tableRoot);

      this.container.appendChild(tableRootFrag);

      if (rootNode.waypoints > 1) {
        // Now that the above work has been added to the live DOM, start observing
        // the middle node in order to populate the next empty waypoint
        const obsSelector = `[data-parent-id="${rootNodeDivId}"][data-waypoint-number="0"] > [data-observe-next-wp]`;
        const obsTarget = document.querySelector(obsSelector);

        this.waypointObserver.observe(obsTarget);
      }
    }

    /**
     * Build a parent node's waypoint scaffold and populate the first waypoint.
     * This is called when any parent is expanded for the first time, then
     * the waypointObserver takes over to populate any next empty waypoints.
     * @param {string} nodeDivId - Div id of the parent node,
     * ie: 'archival_object_18028'
     */
    async initNodeChildren(nodeDivId) {
      const nodeId = nodeDivId.split('_')[2];
      const node = await this.fetchNode(nodeId);
      const nodeLevel = parseInt(
        document
          .querySelector(`#${nodeDivId}`)
          .closest('.table-row-group')
          .getAttribute('data-waypoint-level'),
        10
      );
      const nodeWpCount = node.waypoints;
      const nodeUri = `/repositories/${this.repoId}/archival_objects/${nodeId}`;

      this.nodeWaypointsScaffold(nodeDivId, nodeLevel + 1, nodeWpCount);

      const firstWP = document.querySelector(
        `[data-parent-id="${nodeDivId}"][data-waypoint-number="0"]`
      );

      this.populateWaypoint(
        firstWP,
        node.precomputed_waypoints[nodeUri][0],
        nodeLevel + 1,
        nodeWpCount > 1
      );

      if (nodeWpCount > 1) {
        this.waypointObserver.observe(
          firstWP.querySelector('[data-observe-next-wp]')
        );
      }
    }

    /**
     * Fetch the root node of the tree
     * @returns {Object} - Root node object as returned from the server
     */
    async fetchRootNode() {
      try {
        const response = await fetch(this.appUrlPrefix + this.rootUri);

        return await response.json();
      } catch (err) {
        console.error(err);
      }
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
     * Fetch the next waypoint of the given node
     * @param {Object} params - Object of params for the ajax call with the signature:
     * @param {string} params.node - Node URL param in the form of '' or
     * '/repositories/X/archival_objects/Y'
     * @param {number} params.offset - Offset URL param
     * @returns {array} - Array of waypoint objects as returned from the server
     */
    async fetchWaypoint(params) {
      const query = new URLSearchParams();

      for (const key in params) {
        query.append(key, params[key]);
      }

      try {
        const response = await fetch(`${this.waypointUri}?${query}`);
        const waypoint = await response.json();

        return waypoint;
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Append the root row to the tree container
     * @param {string} title - Title of the root node
     * @returns {DocumentFragment} - DocumentFragment containing the root row
     */
    rootRowMarkup(title) {
      const titleContent = new MixedContent(title);
      const rootRowFrag = new DocumentFragment();
      const rootRow = document
        .querySelector('#infinite-tree-root-row-template')
        .content.cloneNode(true);

      rootRow.querySelector('.table-row').id = `resource_${this.resourceId}`;
      rootRow
        .querySelector('.table-row')
        .setAttribute('data-uri', this.resourceUri);

      rootRow
        .querySelector('.title')
        .setAttribute(
          'title',
          titleContent.isMixed ? titleContent.derivedString : titleContent.input
        );

      rootRow.querySelector(
        '.record-title'
      ).href = `#tree::resource_${this.resourceId}`;

      if (titleContent.isMixed) {
        rootRow.querySelector('.record-title').innerHTML = titleContent.input;
      } else {
        rootRow.querySelector('.record-title').textContent = titleContent.input;
      }

      rootRowFrag.appendChild(rootRow);

      return rootRowFrag;
    }

    /**
     * Build the waypoints of a node and populate its first waypoint
     * @param {number} nodeId - Div id of the parent node whose waypoints
     * are being scaffolded
     * @param {number} level - Level of the waypoints
     * @param {number} numWPs - Number of waypoints to create
     * @returns {DocumentFragment} - DocumentFragment containing the waypoint
     */
    rootNodeWaypointsScaffold(nodeId, level, numWPs) {
      const nodeWaypointsFrag = new DocumentFragment();

      for (let i = 0; i < numWPs; i++) {
        const tableRowGroup = document.createElement('div');
        tableRowGroup.className = 'table-row-group';
        tableRowGroup.setAttribute('data-parent-id', nodeId);
        tableRowGroup.setAttribute('data-waypoint-number', i);
        tableRowGroup.setAttribute('data-waypoint-level', level);
        tableRowGroup.setAttribute('role', 'list');

        const tableRow = document.createElement('div');
        tableRow.className = `table-row waypoint indent-level-${level}`;

        tableRowGroup.appendChild(tableRow);

        nodeWaypointsFrag.appendChild(tableRowGroup);
      }

      return nodeWaypointsFrag;
    }

    /**
     * Build the markup for a node row
     * @param {Object} node - Node data
     * @param {number} level - Indent level of the node
     * @param {boolean} shouldObserve - Whether or not to observe the node
     * in order to populate the next empty waypoint
     * @param {number} [parentId=null] - Optional ID of the node's parent; if null
     * then parent is assumed to be the root resource
     * @param {number} [offset=null] - Optional offset of the next waypoint to
     * populate; required if `shouldObserve` is true
     * @returns {DocumentFragment} - DocumentFragment containing the node row
     */
    nodeRowMarkup(node, level, shouldObserve, parentId = null, offset = null) {
      const aoId = node.uri.split('/')[4];
      const divId = `archival_object_${aoId}`;
      const titleContent = new MixedContent(this.nodeTitle(node));
      const aHref = `#tree::${divId}`;

      const nodeRowFrag = new DocumentFragment();

      const nodeRow = document
        .querySelector('#infinite-tree-node-row-template')
        .content.cloneNode(true);

      nodeRow.querySelector('.table-row').id = divId;
      nodeRow
        .querySelector('.table-row')
        .classList.add(`indent-level-${level}`);
      nodeRow.querySelector('.table-row').setAttribute('data-uri', node.uri);

      if (shouldObserve) {
        const nodeParam = parentId.startsWith('resource')
          ? ''
          : `/repositories/${this.repoId}/archival_objects/${
              parentId.split('_')[2]
            }`;

        nodeRow
          .querySelector('.table-row')
          .setAttribute('data-observe-next-wp', true);
        nodeRow
          .querySelector('.table-row')
          .setAttribute('data-observe-node', nodeParam);
        nodeRow
          .querySelector('.table-row')
          .setAttribute('data-observe-offset', offset);
      }

      nodeRow
        .querySelector('.title')
        .setAttribute(
          'title',
          titleContent.isMixed ? titleContent.derivedString : titleContent.input
        );

      if (node.child_count == 0) {
        nodeRow.querySelector('.expandme').style.visibility = 'hidden';
        nodeRow.querySelector('.expandme').setAttribute('aria-hidden', 'true');
      } else if (node.child_count > 0) {
        nodeRow
          .querySelector('.table-row')
          .setAttribute('data-has-expanded', false);
        nodeRow
          .querySelector('.table-row')
          .setAttribute('data-is-expanded', false);
        nodeRow
          .querySelector('.expandme')
          .setAttribute('aria-expanded', 'false');
      }

      nodeRow.querySelector('.sr-only').textContent = titleContent.isMixed
        ? titleContent.derivedString
        : titleContent.input;

      if (node.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;
        nodeRow
          .querySelector('.record-title')
          .insertAdjacentHTML('beforebegin', iconHtml);
      }

      nodeRow.querySelector('.record-title').setAttribute('href', aHref);

      if (titleContent.isMixed) {
        nodeRow.querySelector('.record-title').innerHTML = titleContent.input;
      } else {
        nodeRow.querySelector('.record-title').textContent = titleContent.input;
      }

      nodeRowFrag.appendChild(nodeRow);

      return nodeRowFrag;
    }

    /**
     * Append the empty set of waypoint containers belonging to a node after
     * the node element; append elements manually because `insertAdjacentElement()`
     * @param {number} nodeId - Div id of the parent node whose waypoints
     * are being scaffolded
     * @param {number} level - Level of the waypoints
     * @param {number} numWPs - Number of waypoints to create
     * @todo - refactor to use DocumentFragment and <template>
     */
    nodeWaypointsScaffold(nodeId, level, numWPs) {
      for (let i = 0; i < numWPs; i++) {
        const prevSibling =
          i === 0
            ? document.querySelector(`#${nodeId}`)
            : document.querySelector(
                `[data-parent-id="${nodeId}"][data-waypoint-number="${i - 1}"]`
              );

        const tableRowGroup = document.createElement('div');
        tableRowGroup.className = 'table-row-group';
        tableRowGroup.setAttribute('data-parent-id', nodeId);
        tableRowGroup.setAttribute('data-waypoint-number', i);
        tableRowGroup.setAttribute('data-waypoint-level', level);
        tableRowGroup.setAttribute('role', 'list');

        const tableRow = document.createElement('div');
        tableRow.className = `table-row waypoint indent-level-${level}`;

        prevSibling.insertAdjacentElement('afterend', tableRowGroup);

        const liveTableRowGroup = document.querySelector(
          `[data-parent-id="${nodeId}"][data-waypoint-number="${i}"]`
        );

        liveTableRowGroup.appendChild(tableRow);
      }
    }

    /**
     * Populate an empty waypoint with nodes
     * @param {HTMLElement} waypoint - The empty waypoint to populate
     * @param {array} nodes - Array of node objects to populate the waypoint with
     * @param {number} level - Level of the waypoint
     * @param {boolean} hasNextEmptyWP - Whether or not there is a next empty waypoint
     */
    populateWaypoint(waypoint, nodes, level, hasNextEmptyWP) {
      const waypointMarker = waypoint.querySelector('.waypoint');
      const nodeRowsFrag = new DocumentFragment();

      waypointMarker.classList.add('populated');

      nodes.forEach((node, i) => {
        // observe the middle node if there is a next empty waypoint
        const observeThisNode =
          i == Math.floor(this.WAYPOINT_SIZE / 2) - 1 && hasNextEmptyWP;
        const markupArgs = [node, level, observeThisNode];

        if (observeThisNode) {
          const nodeParentId = waypoint.getAttribute('data-parent-id');
          const nodeWpNum = parseInt(
            waypoint.getAttribute('data-waypoint-number'),
            10
          );

          markupArgs.push(nodeParentId, nodeWpNum + 1);
        }

        nodeRowsFrag.appendChild(this.nodeRowMarkup(...markupArgs));
      });

      waypoint.appendChild(nodeRowsFrag);
    }

    /**
     * IntersectionObserver callback for populating the next empty waypoint
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     * @param {IntersectionObserver} observer - The observer instance
     */
    waypointScrollHandler(entries, observer) {
      entries.forEach(async entry => {
        if (entry.isIntersecting) {
          const thisWaypoint = entry.target.closest('.table-row-group');

          if (!this.nextSiblingIsNextWaypoint(thisWaypoint)) {
            return;
          }

          const node = entry.target.getAttribute('data-observe-node');
          const offset = entry.target.getAttribute('data-observe-offset');
          const nodes = await this.fetchWaypoint({ node, offset });
          const level = thisWaypoint.getAttribute('data-waypoint-level');
          const nextWaypoint = thisWaypoint.nextElementSibling;
          const nextWPHasNextWP = this.nextSiblingIsNextWaypoint(nextWaypoint);

          this.populateWaypoint(nextWaypoint, nodes, level, nextWPHasNextWP);

          if (nextWPHasNextWP) {
            const nextWPTarget = nextWaypoint.querySelector(
              '[data-observe-next-wp="true"]'
            );

            observer.observe(nextWPTarget);
          }

          entry.target.removeAttribute('data-observe-next-wp');
          entry.target.removeAttribute('data-observe-node');
          entry.target.removeAttribute('data-observe-offset');

          observer.unobserve(entry.target);
        }
      });
    }

    /**
     * Determine if the next sibling of the given waypoint is the next
     * empty waypoint of the same parent
     * @param {HTMLElement} waypoint - The waypoint with a possible next sibling
     * @returns {boolean} - True if the next sibling is the next empty waypoint
     * of the same parent
     */
    nextSiblingIsNextWaypoint(waypoint) {
      const nextSibling = waypoint.nextElementSibling;

      if (!nextSibling) {
        return false;
      }

      const thisWpParent = waypoint.getAttribute('data-parent-id');
      const thisWpNum = parseInt(
        waypoint.getAttribute('data-waypoint-number'),
        10
      );

      const nextSiblingParent = nextSibling.getAttribute('data-parent-id');
      const nextSiblingWpNum = parseInt(
        nextSibling.getAttribute('data-waypoint-number'),
        10
      );
      const nextSiblingFirstChild = nextSibling.firstElementChild;

      return (
        nextSiblingParent == thisWpParent &&
        nextSiblingWpNum == thisWpNum + 1 &&
        nextSiblingFirstChild.classList.contains('waypoint') &&
        !nextSiblingFirstChild.classList.contains('populated')
      );
    }

    /**
     * Handle click events on expandme buttons or their child icons
     * @param {Event} e - Click event
     */
    expandHandler(e) {
      const node = e.target.closest('.largetree-node');
      const button =
        e.target.className === 'expandme'
          ? e.target
          : e.target.closest('.expandme');
      const icon = e.target.classList.contains('expandme-icon')
        ? e.target
        : e.target.querySelector('.expandme-icon');

      button.setAttribute(
        'aria-expanded',
        button.getAttribute('aria-expanded') === 'true' ? 'false' : 'true'
      );

      icon.classList.toggle('expanded');

      node.setAttribute(
        'data-is-expanded',
        button.getAttribute('aria-expanded')
      );

      if (node.getAttribute('data-has-expanded') === 'false') {
        this.initNodeChildren(node.id);

        node.setAttribute('data-has-expanded', true);
      }
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
