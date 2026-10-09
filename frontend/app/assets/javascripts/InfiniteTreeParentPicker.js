//= require InfiniteTree

(function (exports) {
  const PLACEMENT_ACTION_CLASSES = Object.freeze({
    before: 'add-items-before',
    child: 'add-items-as-children',
    after: 'add-items-after',
  });
  const SPAWN_ANCHOR_CLASS = 'spawn-anchor';

  /**
   * @typedef {Object} ParentPickerPlacement
   * @property {string|undefined} parentUri - Backend URI of the new record's
   * parent, or undefined when the root record is the parent
   * @property {number} position - Position of the new record among its siblings
   */

  /**
   * Browse-only InfiniteTree host for choosing where a new child record will be
   * created: before, as the first child of†, or after an existing node. Used by
   * TreeLinkingModal on the standalone new Archival Object page.
   *
   * † This is parity with the legacy LargeTree picker; although the other "into"
   * placements (Paste, Drop) append the record rather than prepending it.
   *
   * On top of the core tree, the picker owns:
   * - the anchor, the one real node marked `.spawn-anchor` while its menu is
   *   open; the class is cleared once a placement is chosen
   * - the before/child/after placement menu for the anchor
   * - a picker-local placeholder row where the new record will appear
   *
   * It does not instantiate InfiniteTreeRouter, InfiniteTreeRecordPane,
   * InfiniteTreeResizer, the toolbar, or the reorder modules, and it does not
   * call InfiniteTree#setCurrentNode, which is record-pane oriented.
   */
  class InfiniteTreeParentPicker {
    static PLACEMENTS = Object.freeze(['before', 'child', 'after']);

    /** @type {HTMLElement} */
    #containerEl;

    /** @type {InfiniteTree} */
    #tree;

    /** @type {{before: string, child: string, after: string}} */
    #menuLabels;

    /** @type {string} */
    #placeholderHtml;

    /** @type {function(?ParentPickerPlacement, {userInitiated: boolean}): void} */
    #onPlacementChange;

    /** @type {HTMLElement|null} */
    #anchor = null;

    /** @type {HTMLElement|null} */
    #menuEl = null;

    /** @type {HTMLElement|null} */
    #placeholderEl = null;

    /**
     * A child list the picker created to hold the placeholder, and the parent's
     * original aria-expanded value to restore when the list is removed.
     * @type {{list: HTMLElement, parent: HTMLElement, ariaExpanded: (string|null)}|null}
     */
    #createdChildList = null;

    /** @type {ParentPickerPlacement|null} */
    #placement = null;

    /** Incremented to invalidate an in-flight child placement. */
    #placementRequest = 0;

    #destroyed = false;

    /** @type {Array<[EventTarget, string, EventListener, (boolean|undefined)]>} */
    #listeners = [];

    /** @type {Array<[EventTarget, string, EventListener, (boolean|undefined)]>} */
    #menuListeners = [];

    /**
     * @param {Object} options
     * @param {HTMLElement} options.mountEl - Element whose content is replaced
     * with the picker scaffold
     * @param {string} options.rootUri - Backend URI of the root record, e.g.
     * "/repositories/2/resources/5"
     * @param {{sep: string, bulk: string, enumerations: Object}} options.i18n -
     * InfiniteTree markup i18n
     * @param {{before: string, child: string, after: string}} options.menuLabels
     * - Labels for the placement actions
     * @param {string} options.placeholderHtml - Trusted, server-translated HTML
     * shown after the asterisk in the placeholder row's title
     * @param {function(?ParentPickerPlacement, {userInitiated: boolean}): void} [options.onPlacementChange]
     * - Called with the new placement, or null when there is none;
     * `userInitiated` is false for the empty-tree default placement and when a
     * placement is cleared
     */
    constructor({
      mountEl,
      rootUri,
      i18n,
      menuLabels,
      placeholderHtml,
      onPlacementChange = () => {},
    }) {
      const scaffold = document
        .querySelector('#infinite-tree-parent-picker-template')
        .content.cloneNode(true);
      const componentEl = scaffold.querySelector('#infinite-tree-component');

      componentEl.dataset.rootUri = rootUri;

      this.#containerEl = scaffold.querySelector('#infinite-tree-container');
      this.#menuLabels = menuLabels;
      this.#placeholderHtml = placeholderHtml;
      this.#onPlacementChange = onPlacementChange;

      mountEl.replaceChildren(scaffold);

      this.#tree = new InfiniteTree(i18n, {
        componentEl,
        containerEl: this.#containerEl,
        resizable: false,
      });

      const container = this.#containerEl;

      this.#listen(
        this.#listeners,
        container,
        InfiniteTree.EVENT_TYPE_TITLE_CLICK,
        e => this.#activate(e.detail && e.detail.node)
      );
      this.#listen(this.#listeners, container, 'click', e =>
        this.#onContainerClick(e)
      );
      this.#listen(this.#listeners, container, 'keydown', e =>
        this.#onContainerKeydown(e)
      );
      this.#listen(this.#listeners, container, 'keyup', e =>
        this.#onContainerKeyup(e)
      );
      // Realizing rows above the anchor shifts it; keep an open menu attached
      this.#listen(this.#listeners, container, 'infiniteTree:didExpand', () =>
        this.#positionMenu()
      );
      this.#listen(
        this.#listeners,
        container,
        'infiniteTree:didInsertBatch',
        () => this.#positionMenu()
      );
    }

    /**
     * Renders the root record and its first batch of children. When the root
     * has no children, the new record becomes its only child without a choice.
     * @returns {Promise<void>}
     */
    async load() {
      if (this.#destroyed) return;

      let root;

      try {
        root = await this.#tree.renderRoot();
      } catch (error) {
        console.error(
          'InfiniteTreeParentPicker could not load the tree:',
          error
        );

        return;
      }

      if (this.#destroyed || !root) return;

      // The root is context, not a placement anchor, so drop its link semantics
      root
        .querySelector(':scope > .node-row .record-title')
        ?.removeAttribute('href');

      if (Number(root.dataset.childCount || 0) === 0) {
        this.#placeholderEl = this.#createPlaceholder(1);
        this.#childListFor(root, 1).appendChild(this.#placeholderEl);
        this.#setPlacement({ parentUri: undefined, position: 0 }, false);
      }
    }

    /** @returns {ParentPickerPlacement|null} */
    get placement() {
      return this.#placement ? { ...this.#placement } : null;
    }

    /**
     * Closes the menu, removes the picker's listeners, and destroys its tree.
     * Call whenever the hosting modal closes, including on cancel.
     */
    destroy() {
      if (this.#destroyed) return;

      this.#destroyed = true;
      this.#placementRequest += 1;
      this.#closeMenu();
      this.#unlisten(this.#listeners);
      this.#tree.destroy();
    }

    /**
     * Makes a real, non-root node the anchor and opens its placement menu.
     * Activating a different node discards the previous placement. Each
     * activation applies `.spawn-anchor` until a menu action inserts the
     * placeholder.
     * @param {HTMLElement|null|undefined} node
     */
    #activate(node) {
      if (!this.#isActivatable(node)) return;

      if (node !== this.#anchor) {
        this.#clearPlacement();
      }

      this.#setSpawnAnchor(node);
      this.#anchor = node;
      this.#openMenu();
    }

    /**
     * @param {*} node
     * @returns {boolean}
     */
    #isActivatable(node) {
      return (
        !this.#destroyed &&
        node instanceof HTMLElement &&
        node.matches(
          'li.node:not(.root, .spawn-placeholder, .js-itree-synthetic-new)'
        ) &&
        this.#containerEl.contains(node)
      );
    }

    /**
     * Whole-row activation. Expand clicks belong to InfiniteTree, and title
     * clicks arrive as InfiniteTree titleClick events.
     * @param {MouseEvent} e
     */
    #onContainerClick(e) {
      if (this.#isInMenu(e.target)) return;
      if (e.target.closest('.node-expand, .record-title')) return;

      const row = e.target.closest('.node-row');

      if (row) this.#activate(row.parentElement);
    }

    /**
     * Space on a focused title activates its row on keyup, as a native button
     * would, so the keyup cannot reach the menu that activation focuses. Enter
     * clicks the title link natively, which arrives as a titleClick event.
     * @param {KeyboardEvent} e
     */
    #onContainerKeydown(e) {
      if (e.key === ' ' && this.#keyedTitle(e)) e.preventDefault();
    }

    /** @param {KeyboardEvent} e */
    #onContainerKeyup(e) {
      if (e.key !== ' ') return;

      const title = this.#keyedTitle(e);

      if (!title) return;

      e.preventDefault();
      this.#activate(title.closest('li.node'));
    }

    /**
     * @param {KeyboardEvent} e
     * @returns {HTMLElement|null} The record title receiving the key, if any
     */
    #keyedTitle(e) {
      if (this.#isInMenu(e.target)) return null;

      return e.target.closest('.record-title');
    }

    /**
     * @param {EventTarget} target
     * @returns {boolean}
     */
    #isInMenu(target) {
      return !!this.#menuEl && this.#menuEl.contains(target);
    }

    /** Opens the placement menu below the anchor's row and focuses it. */
    #openMenu() {
      this.#closeMenu();

      const menu = document.createElement('ul');
      const anchorTitle = this.#anchorTitle();

      menu.className = 'dropdown-menu show infinite-tree-parent-picker__menu';
      menu.setAttribute('role', 'menu');
      menu.setAttribute(
        'aria-label',
        (anchorTitle && anchorTitle.getAttribute('title')) || ''
      );

      InfiniteTreeParentPicker.PLACEMENTS.forEach(placement => {
        const item = document.createElement('li');
        const action = document.createElement('button');

        item.setAttribute('role', 'none');
        action.type = 'button';
        action.className = `dropdown-item ${PLACEMENT_ACTION_CLASSES[placement]}`;
        action.setAttribute('role', 'menuitem');
        action.tabIndex = -1;
        action.dataset.placement = placement;
        action.textContent = this.#menuLabels[placement];

        item.appendChild(action);
        menu.appendChild(item);
      });

      this.#containerEl.appendChild(menu);
      this.#menuEl = menu;

      this.#listen(this.#menuListeners, menu, 'click', e => {
        const action = e.target.closest('[data-placement]');

        if (action) this.#choose(action.dataset.placement);
      });
      this.#listen(this.#menuListeners, menu, 'keydown', e =>
        this.#onMenuKeydown(e)
      );
      // Moving focus to another control (Tab, Shift+Tab) closes the menu
      this.#listen(this.#menuListeners, menu, 'focusout', e => {
        if (e.relatedTarget && !menu.contains(e.relatedTarget)) {
          this.#closeMenu();
        }
      });
      // So does a pointer interaction outside the menu, before it is handled
      this.#listen(
        this.#menuListeners,
        document,
        'pointerdown',
        e => {
          if (!menu.contains(e.target)) {
            this.#closeMenu({ clearSpawnAnchor: true });
          }
        },
        true
      );

      this.#positionMenu();
      menu.scrollIntoView({ block: 'nearest' });
      menu.querySelector('[role="menuitem"]').focus({ preventScroll: true });
    }

    /**
     * Removes the placement menu, if it is open.
     * @param {Object} [options]
     * @param {boolean} [options.restoreFocus=false] - Focus the anchor's title
     * @param {boolean} [options.clearSpawnAnchor=false] - Drop `.spawn-anchor`
     */
    #closeMenu({ restoreFocus = false, clearSpawnAnchor = false } = {}) {
      if (!this.#menuEl) return;

      this.#unlisten(this.#menuListeners);
      this.#menuEl.remove();
      this.#menuEl = null;

      if (clearSpawnAnchor) this.#clearSpawnAnchor();

      if (restoreFocus) this.#anchorTitle()?.focus();
    }

    /**
     * Arrow keys and Home/End move among the placement actions; Escape closes
     * the menu without closing the modal, clears `.spawn-anchor`, and returns
     * focus to the row title. Enter and Space activate the focused action.
     * @param {KeyboardEvent} e
     */
    #onMenuKeydown(e) {
      const actions = Array.from(
        this.#menuEl.querySelectorAll('[role="menuitem"]')
      );
      const last = actions.length - 1;
      const index = actions.indexOf(document.activeElement);
      let next;

      switch (e.key) {
        case 'ArrowDown':
          next = actions[index < 0 || index === last ? 0 : index + 1];
          break;
        case 'ArrowUp':
          next = actions[index <= 0 ? last : index - 1];
          break;
        case 'Home':
          next = actions[0];
          break;
        case 'End':
          next = actions[last];
          break;
        case 'Escape':
          e.preventDefault();
          e.stopPropagation();
          this.#closeMenu({ restoreFocus: true, clearSpawnAnchor: true });

          return;
        default:
          return;
      }

      e.preventDefault();
      next.focus();
    }

    /** Keeps the open menu below the anchor's row, aligned with its title. */
    #positionMenu() {
      if (!this.#menuEl || !this.#anchor) return;

      const row = this.#anchor.querySelector(':scope > .node-row');

      if (!row) return;

      const container = this.#containerEl;
      const containerRect = container.getBoundingClientRect();
      const titleRect = (this.#anchorTitle() || row).getBoundingClientRect();
      const top =
        row.getBoundingClientRect().bottom -
        containerRect.top -
        container.clientTop +
        container.scrollTop;
      const left =
        titleRect.left -
        containerRect.left -
        container.clientLeft +
        container.scrollLeft;
      const maxLeft = Math.max(
        0,
        container.scrollLeft + container.clientWidth - this.#menuEl.offsetWidth
      );

      this.#menuEl.style.top = `${top}px`;
      this.#menuEl.style.left = `${Math.min(Math.max(0, left), maxLeft)}px`;
    }

    /**
     * Places the new record relative to the anchor and shows the placeholder.
     * - before: the anchor's parent, at the anchor's position
     * - after: the anchor's parent, after the anchor and its whole subtree
     * - child: the anchor, as its first child, once its children are realized
     * @param {string} placement - 'before', 'child', or 'after'
     */
    async #choose(placement) {
      const anchor = this.#anchor;

      if (!anchor || this.#destroyed) return;

      this.#closeMenu({ restoreFocus: true });
      this.#clearPlacement();

      const request = this.#placementRequest;
      let result;

      if (placement === 'child') {
        try {
          await this.#tree.expandNode(anchor);
        } catch (error) {
          console.error(
            'InfiniteTreeParentPicker could not expand the anchor:',
            error
          );

          return;
        }

        if (request !== this.#placementRequest || this.#destroyed) return;

        const level = this.#levelOf(anchor) + 1;

        this.#placeholderEl = this.#createPlaceholder(level);
        this.#childListFor(anchor, level).prepend(this.#placeholderEl);
        result = { parentUri: anchor.dataset.uri, position: 0 };
      } else {
        const position = this.#positionOf(anchor);

        this.#placeholderEl = this.#createPlaceholder(this.#levelOf(anchor));

        if (placement === 'before') {
          anchor.before(this.#placeholderEl);
          result = { parentUri: this.#parentUriOf(anchor), position };
        } else {
          anchor.after(this.#placeholderEl);
          result = {
            parentUri: this.#parentUriOf(anchor),
            position: position + 1,
          };
        }
      }

      this.#placeholderEl.scrollIntoView({ block: 'nearest' });
      this.#setPlacement(result, true);
      this.#clearSpawnAnchor();
    }

    /** @param {HTMLElement} node */
    #setSpawnAnchor(node) {
      this.#clearSpawnAnchor();
      node.classList.add(SPAWN_ANCHOR_CLASS);
    }

    /** Removes `.spawn-anchor` from every row in the picker tree. */
    #clearSpawnAnchor() {
      this.#containerEl
        .querySelectorAll(`li.node.${SPAWN_ANCHOR_CLASS}`)
        .forEach(anchor => anchor.classList.remove(SPAWN_ANCHOR_CLASS));
    }

    /**
     * Removes the placeholder, and any child list created for it, and clears
     * the placement.
     */
    #clearPlacement() {
      this.#placementRequest += 1;

      this.#placeholderEl?.remove();
      this.#placeholderEl = null;

      if (this.#createdChildList) {
        const { list, parent, ariaExpanded } = this.#createdChildList;

        list.remove();

        if (ariaExpanded === null) parent.removeAttribute('aria-expanded');
        else parent.setAttribute('aria-expanded', ariaExpanded);

        this.#createdChildList = null;
      }

      if (this.#placement) this.#setPlacement(null, false);
    }

    /**
     * @param {ParentPickerPlacement|null} placement
     * @param {boolean} userInitiated
     */
    #setPlacement(placement, userInitiated) {
      this.#placement = placement;
      this.#onPlacementChange(placement ? { ...placement } : null, {
        userInitiated,
      });
    }

    /**
     * @param {number} level - Tree level of the placeholder row
     * @returns {HTMLElement} A new placeholder row
     */
    #createPlaceholder(level) {
      const placeholder = document
        .querySelector('#infinite-tree-spawn-placeholder-template')
        .content.firstElementChild.cloneNode(true);

      placeholder.classList.add(`indent-level-${level}`);
      placeholder
        .querySelector('.record-title')
        .insertAdjacentHTML('beforeend', this.#placeholderHtml);

      return placeholder;
    }

    /**
     * Returns the node's child list, creating a picker-local list when the
     * node has no children: a leaf, or the root of an empty tree.
     * @param {HTMLElement} node
     * @param {number} level - Tree level of the node's children
     * @returns {HTMLElement}
     */
    #childListFor(node, level) {
      const existing = node.querySelector(':scope > ol.node-children');

      if (existing) return existing;

      const list = document.createElement('ol');

      list.className = 'node-children';
      list.setAttribute('role', 'group');
      list.dataset.parentId = node.id;
      list.dataset.treeLevel = String(level);
      list.dataset.totalChildBatches = '0';

      this.#createdChildList = {
        list,
        parent: node,
        ariaExpanded: node.getAttribute('aria-expanded'),
      };
      node.setAttribute('aria-expanded', 'true');
      node.appendChild(list);

      return list;
    }

    /** @returns {HTMLElement|null} The anchor's record title */
    #anchorTitle() {
      return this.#anchor
        ? this.#anchor.querySelector(':scope > .node-row .record-title')
        : null;
    }

    /**
     * @param {HTMLElement} node - A non-root node
     * @returns {number} Tree level of the node (1 for the root's children)
     */
    #levelOf(node) {
      const match = node.className.match(/\bindent-level-(\d+)\b/);

      return match ? Number(match[1]) : 1;
    }

    /**
     * @param {HTMLElement} node - A non-root node
     * @returns {number} The node's position among its siblings
     */
    #positionOf(node) {
      const position = Number(node.dataset.treePosition);

      if (Number.isInteger(position)) return position;

      // Batches realize in order in the picker, so earlier siblings are present
      return Array.from(node.parentElement.children)
        .filter(sibling => sibling.matches('li.node:not(.spawn-placeholder)'))
        .indexOf(node);
    }

    /**
     * @param {HTMLElement} node - A non-root node
     * @returns {string|undefined} Backend URI of the node's parent, or undefined
     * when the parent is the root record, which leaves the new record's parent
     * unset
     */
    #parentUriOf(node) {
      const parent = node.parentElement.closest('li.node');

      if (!parent || parent.classList.contains('root')) return undefined;

      return parent.dataset.uri;
    }

    /**
     * Adds an event listener and records it in the given registry for removal.
     * @param {Array} registry
     * @param {EventTarget} target
     * @param {string} type
     * @param {EventListener} handler
     * @param {boolean} [capture]
     */
    #listen(registry, target, type, handler, capture) {
      target.addEventListener(type, handler, capture);
      registry.push([target, type, handler, capture]);
    }

    /**
     * Removes and forgets every listener in the given registry.
     * @param {Array} registry
     */
    #unlisten(registry) {
      registry.forEach(([target, type, handler, capture]) => {
        target.removeEventListener(type, handler, capture);
      });
      registry.length = 0;
    }
  }

  exports.InfiniteTreeParentPicker = InfiniteTreeParentPicker;
})(window);
