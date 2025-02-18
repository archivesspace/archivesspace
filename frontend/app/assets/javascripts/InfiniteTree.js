(function (exports) {
  class InfiniteTree {
    /**
     * @constructor
     * @param {number} childSegmentSize - The number of nodes per segment of children
     * @param {string} appUrlPrefix - The proper app prefix
     * @param {string} resourceUri - The URI of the collection resource
     * @param {string} identifier_separator - The i18n identifier separator
     * @param {string} date_type_bulk - The i18n date type bulk
     * @returns {InfiniteTree} - InfiniteTree instance
     */
    constructor(
      childSegmentSize,
      appUrlPrefix,
      resourceUri,
      identifier_separator,
      date_type_bulk
    ) {
      this.CHILD_SEGMENT_SIZE = childSegmentSize;
      this.appUrlPrefix = appUrlPrefix;
      this.resourceUri = resourceUri;
      this.repoId = this.resourceUri.split('/')[2];
      this.resourceId = this.resourceUri.split('/')[4];
      // this.baseUri = `${this.resourceUri}/tree`;
      this.baseUri = `/resources/${this.resourceId}/tree`;
      this.rootUri = `${this.baseUri}/root`;
      this.nodeUri = `${this.baseUri}/node`;
      this.segmentUri = `${this.baseUri}/waypoint`; // TODO: rename endpoint to /segment
      this.i18n = { sep: identifier_separator, bulk: date_type_bulk };

      this.container = document.querySelector('#infinite-tree-container');

      this.childSegmentObserver = new IntersectionObserver(
        // Wrap handler in arrow fn to preserve `this` context
        (entries, observer) => {
          this.childSegmentScrollHandler(entries, observer);
        },
        {
          root: this.container,
          rootMargin: '-30% 0px -30% 0px',
          threshold: 0,
        }
      );

      this.initTree();
    }

    /**
     * Initialize the large tree navigation sidebar with the collection's
     * root node and the first segment of its immediate children
     */
    async initTree() {
      const rootNode = await this.fetchRootNode();
      const rootNodeDivId = `resource_${this.resourceId}`;
      const firstSegmentData = rootNode.precomputed_waypoints[''][0]; // TODO rename the property from waypoints to segments
      const rootFrag = this.rootMarkup(this.nodeTitle(rootNode));
      const rootLi = rootFrag.querySelector('li');
      const rootChildListFrag = this.rootNodeChildrenScaffold(
        rootNodeDivId,
        1,
        rootNode.waypoints // TODO: rename to child_segments_count
      );

      rootLi.appendChild(rootChildListFrag);

      this.container.appendChild(rootFrag);

      const firstSegment = document.querySelector(
        `.children[data-parent-id="${rootNodeDivId}"]`
      );
      this.populateChildSegment(
        firstSegment,
        firstSegmentData,
        1,
        rootNode.waypoints > 1
      );

      if (rootNode.waypoints > 1) {
        // Now that the above work has been added to the live DOM, start observing
        // the middle node in order to populate the next empty segment
        const obsSelector = `[data-parent-id="${rootNodeDivId}"] [data-observe-next-segment]`;
        const obsTarget = document.querySelector(obsSelector);
        this.childSegmentObserver.observe(obsTarget);
      }
    }

    /**
     * Build a parent node's scaffold of empty child segments and populate its first segment.
     * This is called when any parent is expanded for the first time, then
     * the childSegmentObserver takes over to populate any next empty segments.
     * @param {string} nodeDivId - Div id of the parent node,
     * ie: 'archival_object_18028'
     */
    async initNodeChildren(nodeDivId) {
      const nodeId = nodeDivId.split('_')[2];
      const node = await this.fetchNode(nodeId);
      const nodeLevel = parseInt(
        document
          .querySelector(`#${nodeDivId}`)
          .closest('.children')
          .getAttribute('data-tree-level'),
        10
      );
      const nodeSegmentCount = node.waypoints;
      const nodeUri = `/repositories/${this.repoId}/archival_objects/${nodeId}`;

      const parentNode = document.querySelector(`#${nodeDivId}`);

      const childListFrag = this.nodeChildrenScaffold(
        nodeDivId,
        nodeLevel + 1,
        nodeSegmentCount
      );
      parentNode.appendChild(childListFrag);

      const childList = document.querySelector(
        `.children[data-parent-id="${nodeDivId}"]`
      );

      this.populateChildSegment(
        childList,
        node.precomputed_waypoints[nodeUri][0],
        nodeLevel + 1,
        nodeSegmentCount > 1
      );

      if (nodeSegmentCount > 1) {
        this.childSegmentObserver.observe(
          childList.querySelector('[data-observe-next-segment]')
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
     * Fetch a segment of the given node's children
     * @param {Object} params - Object of params for the ajax call with the signature:
     * @param {string} params.node - Node URL param in the form of '' or
     * '/repositories/X/archival_objects/Y'
     * @param {number} params.offset - Offset URL param
     * @returns {array} - Array of segment objects as returned from the server
     */
    async fetchSegment(params) {
      const query = new URLSearchParams();

      for (const key in params) {
        query.append(key, params[key]);
      }

      try {
        const response = await fetch(`${this.segmentUri}?${query}`);
        const segment = await response.json();
        console.log('Segment response:', segment);
        return segment;
      } catch (err) {
        console.error('Error fetching segment:', err);
        return null;
      }
    }

    /**
     * Provide the root tree list DocumentFragment
     * @param {string} title - Title of the root node
     * @returns {DocumentFragment} - DocumentFragment containing the tree root
     */
    rootMarkup(title) {
      // const titleContent = new MixedContent(title); // No frontend MixedContent, see ./mixed_content.js
      const rootFrag = new DocumentFragment();
      const rootTemplate = document
        .querySelector('#infinite-tree-root-template')
        .content.cloneNode(true);

      const rootLi = rootTemplate.querySelector('li');
      rootLi.id = `resource_${this.resourceId}`;
      rootLi.setAttribute('data-uri', this.resourceUri);

      const titleDiv = rootTemplate.querySelector('.title');
      titleDiv.setAttribute('title', title);

      const link = rootTemplate.querySelector('.record-title');
      link.href = `#tree::resource_${this.resourceId}`;
      link.textContent = title;

      rootFrag.appendChild(rootTemplate);

      return rootFrag;
    }

    /**
     * Build the root's child segment placeholders
     * @param {number} nodeId - Div id of the parent node whose segments
     * are being scaffolded
     * @param {number} level - Tree level of the segments
     * @param {number} numSegments - Number of segments to create
     * @returns {DocumentFragment} - DocumentFragment containing the root node's
     * scaffold of child segment placeholders
     */
    rootNodeChildrenScaffold(nodeId, level, numSegments) {
      const rootNodeChildrenFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-children-list-template')
        .content.cloneNode(true);

      const listElement = listTemplate.querySelector('ol');
      listElement.setAttribute('data-parent-id', nodeId);
      listElement.setAttribute('data-tree-level', level);
      listElement.setAttribute('data-total-child-segments', numSegments);

      for (let i = 0; i < numSegments; i++) {
        const itemTemplate = document
          .querySelector('#infinite-tree-children-segment-placeholder-template')
          .content.cloneNode(true);
        const itemElement = itemTemplate.querySelector('li');
        itemElement.setAttribute('data-segment-number', i);
        listElement.appendChild(itemElement);
      }

      rootNodeChildrenFrag.appendChild(listTemplate);
      return rootNodeChildrenFrag;
    }

    /**
     * Provide the DocumentFragment for a node
     * @param {Object} node - Node data
     * @param {number} level - Tree level of the node
     * @param {boolean} shouldObserve - Whether or not to observe the node
     * in order to populate a next empty segment
     * @param {number} [parentId=null] - Optional ID of the node's parent; if null
     * then parent is assumed to be the root resource
     * @param {number} [offset=null] - Optional offset of the next segment to
     * populate; required if `shouldObserve` is true
     * @returns {DocumentFragment} - DocumentFragment containing the node
     */
    nodeMarkup(node, level, shouldObserve, parentId = null, offset = null) {
      const aoId = node.uri.split('/')[4];
      const divId = `archival_object_${aoId}`;
      // const titleContent = new MixedContent(this.nodeTitle(node));
      const title = this.nodeTitle(node);
      const aHref = `#tree::${divId}`;

      const nodeFrag = new DocumentFragment();
      const nodeTemplate = document
        .querySelector('#infinite-tree-node-template')
        .content.cloneNode(true);

      const nodeElement = nodeTemplate.querySelector('li');
      nodeElement.id = divId;
      nodeElement.classList.add(`indent-level-${level}`);
      nodeElement.setAttribute('data-uri', node.uri);

      if (node.child_count > 0) {
        const totalSegments = Math.ceil(
          node.child_count / this.CHILD_SEGMENT_SIZE
        );
        nodeElement.setAttribute('data-total-child-segments', totalSegments);
      }

      if (shouldObserve) {
        console.log('Setting up observer with parentId:', parentId);

        let nodeParam = '';
        if (parentId) {
          if (parentId.startsWith('resource')) {
            nodeParam = '';
          } else if (parentId.startsWith('archival_object')) {
            const parentNodeId = parentId.split('_')[2];
            nodeParam = `/repositories/${this.repoId}/archival_objects/${parentNodeId}`;
          }
        }

        console.log('Constructed nodeParam:', nodeParam);

        nodeElement.setAttribute('data-observe-next-segment', 'true');
        nodeElement.setAttribute('data-observe-node', nodeParam);
        nodeElement.setAttribute('data-observe-offset', offset);
      }

      const titleDiv = nodeTemplate.querySelector('.title');
      titleDiv.setAttribute('title', title);

      if (node.child_count == 0) {
        nodeTemplate.querySelector('.expandme').style.visibility = 'hidden';
        nodeTemplate
          .querySelector('.expandme')
          .setAttribute('aria-hidden', 'true');
      } else if (node.child_count > 0) {
        nodeElement.setAttribute('data-has-expanded', false);
        nodeElement.setAttribute('data-is-expanded', false);
        nodeTemplate
          .querySelector('.expandme')
          .setAttribute('aria-expanded', 'false');
      }

      nodeTemplate.querySelector('.sr-only').textContent = title;

      if (node.has_digital_instance) {
        const iconHtml = `<i class="has_digital_instance fa fa-file-image-o" aria-hidden="true"></i>`;
        nodeTemplate
          .querySelector('.record-title')
          .insertAdjacentHTML('beforebegin', iconHtml);
      }

      const link = nodeTemplate.querySelector('.record-title');
      link.setAttribute('href', aHref);
      link.textContent = title;

      nodeFrag.appendChild(nodeTemplate);

      return nodeFrag;
    }

    /**
     * Provide the empty list of child segments belonging to a parent node
     * as a DocumentFragment
     * @param {number} nodeId - id of the parent node whose child list is
     * being scaffolded
     * @param {number} level - Tree level of the children
     * @param {number} numSegments - Number of segments to create
     * @returns {DocumentFragment} - DocumentFragment containing the list
     */
    nodeChildrenScaffold(nodeId, level, numSegments) {
      const nodeChildrenFrag = new DocumentFragment();
      const listTemplate = document
        .querySelector('#infinite-tree-children-list-template')
        .content.cloneNode(true);

      const listElement = listTemplate.querySelector('ol');
      listElement.setAttribute('data-parent-id', nodeId);
      listElement.setAttribute('data-tree-level', level);
      listElement.setAttribute('data-total-child-segments', numSegments);

      for (let i = 0; i < numSegments; i++) {
        const itemTemplate = document
          .querySelector('#infinite-tree-children-segment-placeholder-template')
          .content.cloneNode(true);
        const itemElement = itemTemplate.querySelector('li');
        itemElement.setAttribute('data-segment-number', i);
        listElement.appendChild(itemElement);
      }

      nodeChildrenFrag.appendChild(listTemplate);
      return nodeChildrenFrag;
    }

    /**
     * Populate a child list with a segment of child nodes
     * @param {HTMLElement} list - The child list to populate
     * @param {array} nodes - Array of node objects to populate the list with
     * @param {number} level - Tree level of the list
     * @param {boolean} hasNextSegment - Whether or not there is a next segment
     * @param {number} segmentNumber - The segment number of nodes being populated
     */
    populateChildSegment(
      list,
      nodes,
      level,
      hasNextSegment,
      segmentNumber = 0
    ) {
      if (!Array.isArray(nodes)) {
        console.error('Expected nodes to be an array, got:', nodes);
        return;
      }

      const parentId = list.getAttribute('data-parent-id');
      const nodeRowsFrag = new DocumentFragment();

      nodes.forEach((node, i) => {
        const observeThisNode =
          i == Math.floor(this.CHILD_SEGMENT_SIZE / 2) - 1 && hasNextSegment;

        const markupArgs = [node, level, observeThisNode];

        if (observeThisNode) {
          markupArgs.push(parentId, segmentNumber + 1);
        }

        nodeRowsFrag.appendChild(this.nodeMarkup(...markupArgs));
      });

      // Find and replace the placeholder for this segment
      const placeholder = list.querySelector(
        `li.segment-placeholder[data-segment-number="${segmentNumber}"]`
      );

      if (!placeholder) {
        console.error('Could not find placeholder for segment:', segmentNumber);
        return;
      }

      placeholder.replaceWith(nodeRowsFrag);

      // After appending to DOM, observe the middle node if it exists
      if (hasNextSegment) {
        const observerNode = list.querySelector('[data-observe-next-segment]');
        if (observerNode) {
          console.log(
            'Setting up observer for middle node in segment:',
            segmentNumber
          );
          this.childSegmentObserver.observe(observerNode);
        }
      }
    }

    /**
     * IntersectionObserver callback for populating the next empty segment
     * @param {IntersectionObserverEntry[]} entries - Array of entries
     * @param {IntersectionObserver} observer - The observer instance
     */
    childSegmentScrollHandler(entries, observer) {
      entries.forEach(async entry => {
        if (entry.isIntersecting) {
          const node = entry.target;
          const currentSegment = node.closest('.children');
          const nodeParam = node.getAttribute('data-observe-node');
          const nextSegmentNumber = parseInt(
            node.getAttribute('data-observe-offset'),
            10
          );

          console.log('Observer triggered for:', {
            nodeParam,
            nextSegmentNumber,
            segment: currentSegment.getAttribute('data-parent-id'),
          });

          const response = await this.fetchSegment({
            node: nodeParam,
            offset: nextSegmentNumber,
          });

          if (!response) {
            console.error('Failed to fetch segment');
            return;
          }

          console.log('Segment fetch successful:', {
            responseLength: response.length,
            nextSegmentNumber,
          });

          // Create fragment with the new nodes
          const nodeRowsFrag = new DocumentFragment();
          const level = parseInt(
            currentSegment.getAttribute('data-tree-level'),
            10
          );
          const parentId = currentSegment.getAttribute('data-parent-id');
          const totalSegments = parseInt(
            currentSegment.getAttribute('data-total-child-segments'),
            10
          );
          const hasNextSegment = nextSegmentNumber + 1 < totalSegments;

          // Populate the fragment with the new nodes
          response.forEach((nodeData, i) => {
            const observeThisNode =
              i == Math.floor(this.CHILD_SEGMENT_SIZE / 2) - 1 &&
              hasNextSegment;

            const markupArgs = [nodeData, level, observeThisNode];

            if (observeThisNode) {
              markupArgs.push(parentId, nextSegmentNumber + 1);
            }

            nodeRowsFrag.appendChild(this.nodeMarkup(...markupArgs));
          });

          // Find and replace the placeholder
          const placeholder = currentSegment.querySelector(
            `li.segment-placeholder[data-segment-number="${nextSegmentNumber}"]`
          );

          if (!placeholder) {
            console.error(
              'Could not find placeholder for segment:',
              nextSegmentNumber
            );
            return;
          }

          placeholder.replaceWith(nodeRowsFrag);

          // Clean up the observer on the current segment's middle node
          node.removeAttribute('data-observe-next-segment');
          node.removeAttribute('data-observe-node');
          node.removeAttribute('data-observe-offset');
          observer.unobserve(node);

          // Set up observer on the new middle node if there are more segments
          if (hasNextSegment) {
            const newMiddleNode = currentSegment.querySelector(
              `[data-observe-next-segment][data-observe-offset="${
                nextSegmentNumber + 1
              }"]`
            );
            if (newMiddleNode) {
              console.log(
                'Setting up observer for new middle node in segment:',
                nextSegmentNumber
              );
              this.childSegmentObserver.observe(newMiddleNode);
            } else {
              console.error('Could not find middle node for next segment');
            }
          }
        }
      });
    }

    /**
     * Handle click events on expandme buttons or their child icons
     * @param {Event} e - Click event
     */
    expandHandler(e) {
      console.log('Expanding node:', e.target);
      const node = e.target.closest('.node');
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
