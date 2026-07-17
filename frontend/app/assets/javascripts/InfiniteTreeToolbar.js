class InfiniteTreeToolbar {
  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.toolbarEl = this.componentEl.querySelector('#infinite-tree-toolbar');
    this.treeContainerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    this.recordPaneEl = this.componentEl.querySelector(
      '#infinite-tree-record-pane'
    );

    this.readOnly =
      this.componentEl.getAttribute('data-is-read-only') === 'true';
    this.rootUri = this.componentEl.getAttribute('data-root-uri');
    this.rootType = this.componentEl.getAttribute('data-record-type');

    this.currentNode = null;
    this.isDirty = false;
    this.reorderMode = false;
    this.expandAllMode = false;
    this.cutActive = false;

    this.#bindMoveMenuEvents();
    this.#bindEvents();
    this.#applyReorderState();
    this.#applySelectionState();

    if (this.treeContainerEl) {
      this.treeContainerEl.addEventListener(
        'infiniteTree:autoExpandBusy',
        this.#onAutoExpandBusy.bind(this)
      );
    }
  }

  #bindMoveMenuEvents() {
    if (!this.toolbarEl) return;

    const moveMenu = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-menu'
    );
    if (!moveMenu) return;

    moveMenu.addEventListener('click', this.#onMoveMenuClick.bind(this));
  }

  /**
   * @param {MouseEvent} event
   */
  #onMoveMenuClick(event) {
    const option = event.target.closest('.js-itree-toolbar-move-option');
    if (!option) return;

    if (
      option.hasAttribute('disabled') ||
      option.getAttribute('aria-disabled') === 'true'
    ) {
      return;
    }

    const action = option.getAttribute('data-move-action') || '';
    if (!action) return;

    // Submenu opener shares the down-into action but has no concrete target row.
    if (action === 'down-into' && !option.getAttribute('data-target-node-id')) {
      return;
    }

    event.preventDefault();
    this.#emitSimpleEvent('infiniteTreeToolbar:moveOptionSelected', {
      action,
      targetNodeId: option.getAttribute('data-target-node-id'),
    });
  }

  #bindEvents() {
    if (!this.toolbarEl) return;

    if (this.recordPaneEl) {
      this.recordPaneEl.addEventListener(
        'infiniteTree:nodeSelect',
        this.#handleSelectionChanged.bind(this)
      );
    }

    if (this.recordPaneEl) {
      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:dirty', () => {
        this.isDirty = true;
        this.#applyDirtyState();
      });

      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:clean', () => {
        this.isDirty = false;
        this.#applyDirtyState();
      });
    }

    if (this.treeContainerEl) {
      this.treeContainerEl.addEventListener(
        InfiniteTreeCutPaste.EVENT_CUT_PERFORMED,
        this.#onCutPerformed.bind(this)
      );
      this.treeContainerEl.addEventListener(
        InfiniteTreeCutPaste.EVENT_CUT_CLEARED,
        this.#onCutCleared.bind(this)
      );
      this.treeContainerEl.addEventListener(
        InfiniteTreeSelection.EVENT_CHANGED,
        this.#onSelectionChanged.bind(this)
      );
      this.treeContainerEl.addEventListener(
        InfiniteTreeSelection.EVENT_CLEARED,
        this.#onSelectionCleared.bind(this)
      );
      this.treeContainerEl.addEventListener(
        'infiniteTree:redisplayAndReopenComplete',
        this.#onRedisplayAndReopenComplete.bind(this)
      );
    }

    this.toolbarEl.addEventListener('click', event => {
      const target = event.target.closest('[data-itree-action]');
      if (!target || target.classList.contains('disabled')) return;

      const action = target.getAttribute('data-itree-action');

      switch (action) {
        case 'reorder-toggle':
          this.#onReorderToggle(event, target);

          break;
        case 'cut':
          this.#emitSimpleEvent('infiniteTreeToolbar:cutRequested');
          event.preventDefault();

          break;
        case 'paste':
          this.#emitSimpleEvent('infiniteTreeToolbar:pasteRequested');
          event.preventDefault();

          break;
        case 'move-menu':
          if (this.reorderMode) {
            this.#renderMoveMenu();
          }
          this.#emitSimpleEvent('infiniteTreeToolbar:moveMenuRequested');

          break;
        case 'add-child':
          this.#emitContextualEvent('infiniteTreeToolbar:addChildRequested');

          break;
        case 'add-sibling':
          this.#emitContextualEvent('infiniteTreeToolbar:addSiblingRequested');

          break;
        case 'add-duplicate':
          this.#emitContextualEvent(
            'infiniteTreeToolbar:addDuplicateRequested'
          );

          break;
        case 'load-bulk':
          this.#emitContextualEvent('infiniteTreeToolbar:loadBulkRequested');

          break;
        case 'rde':
          this.#emitContextualEvent('infiniteTreeToolbar:rdeRequested');

          break;
        case 'expand-mode':
          this.#onExpandModeToggle(event, target);

          break;
        case 'collapse-tree':
          this.#onCollapseTree(event);

          break;
        case 'finish-editing':
          this.#onFinishEditingClick(event);

          break;
      }
    });
  }

  #handleSelectionChanged(e) {
    this.currentNode = e.detail && e.detail.node ? e.detail.node : null;
    this.#applySelectionState();
    if (this.reorderMode) {
      this.#applyCutPasteState();
    }
  }

  #applySelectionState() {
    if (!this.toolbarEl) return;

    const isArchivalObjectSelected = this.#isArchivalObjectSelected();
    const moveEnabled = this.reorderMode && this.#hasNonRootSelection();
    const moveToggle = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-toggle'
    );

    if (moveToggle) {
      if (!moveEnabled) {
        moveToggle.classList.add('disabled');
        moveToggle.setAttribute('aria-disabled', 'true');
      } else {
        moveToggle.classList.remove('disabled');
        moveToggle.removeAttribute('aria-disabled');
      }
    }

    const moveGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-group'
    );

    if (moveGroup) {
      moveGroup.style.display = this.reorderMode ? '' : 'none';
    }

    if (this.reorderMode) {
      this.#renderMoveMenu();
    }

    const siblingBtn = this.toolbarEl.querySelector(
      '.js-itree-toolbar-add-sibling'
    );
    if (siblingBtn) {
      siblingBtn.style.display = isArchivalObjectSelected ? '' : 'none';
    }

    const duplicateBtn = this.toolbarEl.querySelector(
      '.js-itree-toolbar-add-duplicate'
    );
    if (duplicateBtn) {
      duplicateBtn.style.display = isArchivalObjectSelected ? '' : 'none';
    }
  }

  #applyDirtyState() {
    if (!this.toolbarEl) return;

    const selector =
      '.js-itree-toolbar-add-child,' +
      '.js-itree-toolbar-add-sibling,' +
      '.js-itree-toolbar-add-duplicate,' +
      '.js-itree-toolbar-load-bulk,' +
      '.js-itree-toolbar-rde,' +
      '.js-itree-toolbar-finish-editing';

    this.toolbarEl.querySelectorAll(selector).forEach(btn => {
      if (this.isDirty) {
        btn.classList.add('disabled');
        btn.setAttribute('aria-disabled', 'true');
      } else {
        btn.classList.remove('disabled');
        btn.removeAttribute('aria-disabled');
      }
    });
  }

  #onReorderToggle(event, btn) {
    event.preventDefault();
    if (this.isDirty) return;

    this.reorderMode = !this.reorderMode;
    if (!this.reorderMode) this.cutActive = false;

    if (btn) {
      btn.classList.toggle('btn-success', this.reorderMode);
      btn.classList.toggle('active', this.reorderMode);
      btn.textContent = this.reorderMode
        ? this.#translate('actions.reorder_active', 'Disable Reorder Mode')
        : this.#translate('actions.enable_reorder', 'Enable Reorder Mode');
    }

    this.#applyReorderState();
    this.#applySelectionState();
    this.#emitSimpleEvent('infiniteTreeToolbar:reorderModeChanged', {
      enabled: this.reorderMode,
    });
  }

  #onExpandModeToggle(event, btn) {
    event.preventDefault();
    this.expandAllMode = !this.expandAllMode;

    btn.classList.toggle('btn-success', this.expandAllMode);
    btn.classList.toggle('btn-default', !this.expandAllMode);
    btn.textContent = this.expandAllMode
      ? this.#translate('actions.expand_tree_mode_off', 'Disable Auto-Expand')
      : this.#translate('actions.expand_tree_mode_on', 'Auto-Expand All');

    this.#emitSimpleEvent('infiniteTreeToolbar:expandModeChanged', {
      enabled: this.expandAllMode,
    });
  }

  #onCutPerformed() {
    this.cutActive = true;
    this.#applyCutPasteState();
  }

  #onCutCleared() {
    this.cutActive = false;
    this.#applyCutPasteState();
  }

  #onSelectionChanged() {
    if (this.reorderMode) {
      this.#syncCurrentNodeFromTree();
      this.#applySelectionState();
      this.#applyCutPasteState();
    } else if (this.cutActive) {
      this.#applyCutPasteState();
    }
  }

  #onSelectionCleared() {
    if (this.reorderMode || this.cutActive) this.#applyCutPasteState();
  }

  #onRedisplayAndReopenComplete() {
    if (!this.reorderMode) return;

    this.#syncCurrentNodeFromTree();
    this.#applySelectionState();
    this.#applyCutPasteState();
  }

  /**
   * Resolve the live tree row that Move menu options apply to. Move always
   * targets the current `.selected` node. After reorder redisplay, cached
   * `currentNode` can reference detached DOM, so read selection from the tree.
   * @returns {HTMLElement|null}
   */
  #getMoveContextNode() {
    if (!this.treeContainerEl) return null;

    const selected = this.treeContainerEl.querySelector('li.node.selected');
    if (selected && !selected.classList.contains('root')) {
      return selected;
    }

    return null;
  }

  #syncCurrentNodeFromTree() {
    const node = this.#getMoveContextNode();
    if (node) {
      this.currentNode = node;
    }
  }

  #onCollapseTree(event) {
    event.preventDefault();

    if (this.expandAllMode) {
      this.expandAllMode = false;
      const expandBtn = this.toolbarEl
        ? this.toolbarEl.querySelector('.js-itree-toolbar-expand-mode')
        : null;

      if (expandBtn) {
        expandBtn.classList.remove('btn-success');
        expandBtn.classList.add('btn-default');
        expandBtn.textContent = this.#translate(
          'actions.expand_tree_mode_on',
          'Auto-Expand All'
        );
      }

      this.#emitSimpleEvent('infiniteTreeToolbar:expandModeChanged', {
        enabled: false,
      });
    }

    this.#emitSimpleEvent('infiniteTreeToolbar:collapseTreeRequested');
  }

  #onAutoExpandBusy(e) {
    const busy = !!(e.detail && e.detail.busy);
    const expandBtn = this.toolbarEl
      ? this.toolbarEl.querySelector('.js-itree-toolbar-expand-mode')
      : null;
    if (!expandBtn) return;

    if (busy) {
      expandBtn.classList.add('disabled');
      expandBtn.setAttribute('disabled', 'disabled');
      expandBtn.setAttribute('aria-disabled', 'true');
    } else {
      expandBtn.classList.remove('disabled');
      expandBtn.removeAttribute('disabled');
      expandBtn.removeAttribute('aria-disabled');
    }
  }

  #onFinishEditingClick(event) {
    event.preventDefault();

    const readonlyPath = window.location.pathname.replace(/\/edit$/, '');
    const target = readonlyPath + window.location.hash;

    this.#emitSimpleEvent('infiniteTreeToolbar:finishEditingRequested', {
      target,
    });

    window.location.href = target;
  }

  #emitSimpleEvent(name, detail) {
    if (!this.treeContainerEl) return;

    const event = new CustomEvent(name, {
      bubbles: true,
      cancelable: true,
      detail: detail || {},
    });

    this.treeContainerEl.dispatchEvent(event);
  }

  #emitContextualEvent(name) {
    if (!this.treeContainerEl) return;

    const event = new CustomEvent(name, {
      bubbles: true,
      cancelable: true,
      detail: {
        node: this.currentNode,
        rootType: this.rootType,
        rootUri: this.rootUri,
      },
    });

    this.treeContainerEl.dispatchEvent(event);
  }

  #translate(key, fallback) {
    if (window.AS && window.AS.I18n && typeof window.AS.I18n.t === 'function') {
      return window.AS.I18n.t(key);
    }

    return fallback;
  }

  #applyReorderState() {
    if (!this.toolbarEl) return;

    const showReorderControls = this.reorderMode;
    const showNonReorderControls = !this.reorderMode;
    const cutPasteGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-cut-paste-group'
    );
    const expandGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-expand-group'
    );
    const primaryActionsGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-primary-actions'
    );

    if (cutPasteGroup) {
      cutPasteGroup.style.display = showReorderControls ? '' : 'none';
    }

    if (expandGroup) {
      expandGroup.style.display = showNonReorderControls ? '' : 'none';
    }

    if (primaryActionsGroup) {
      primaryActionsGroup.style.display = showNonReorderControls ? '' : 'none';
    }

    if (this.recordPaneEl) {
      this.recordPaneEl.style.display = showNonReorderControls ? '' : 'none';
    }

    this.#applyCutPasteState();
  }

  #applyCutPasteState() {
    if (!this.toolbarEl) return;

    const cutBtn = this.toolbarEl.querySelector('.js-itree-toolbar-cut');
    if (cutBtn) {
      const cutEnabled = this.reorderMode && this.#hasEligibleCutNode();
      if (cutEnabled) {
        cutBtn.classList.remove('disabled');
        cutBtn.removeAttribute('aria-disabled');
      } else {
        cutBtn.classList.add('disabled');
        cutBtn.setAttribute('aria-disabled', 'true');
      }
    }

    const pasteBtn = this.toolbarEl.querySelector('.js-itree-toolbar-paste');
    if (!pasteBtn) return;

    const pasteEnabled =
      this.reorderMode && this.cutActive && this.#hasEligiblePasteTarget();
    if (pasteEnabled) {
      pasteBtn.classList.remove('disabled');
      pasteBtn.removeAttribute('aria-disabled');
    } else {
      pasteBtn.classList.add('disabled');
      pasteBtn.setAttribute('aria-disabled', 'true');
    }
  }

  /**
   * Whether at least one row can be cut: multiselected non-root rows, or a
   * selected non-root row when no multiselected rows exist.
   * @returns {boolean}
   */
  #hasEligibleCutNode() {
    if (!this.treeContainerEl) return false;

    const multiselected = this.treeContainerEl.querySelectorAll(
      'li.node.multiselected:not(.root)'
    );
    if (multiselected.length > 0) return true;

    const selected = this.treeContainerEl.querySelector(
      'li.node.selected:not(.root)'
    );
    return !!selected;
  }

  /**
   * Whether a valid paste destination exists: the current `.selected` row
   * that is not `.cut`, including root.
   * @returns {boolean}
   */
  #hasEligiblePasteTarget() {
    if (!this.treeContainerEl) return false;

    return !!this.treeContainerEl.querySelector('li.node.selected:not(.cut)');
  }

  #isArchivalObjectSelected() {
    const node = this.reorderMode
      ? this.#getMoveContextNode()
      : this.currentNode || this.#getSelectedNode();
    if (!node) return false;

    if (node.classList.contains('root')) return false;

    return (node.id || '').indexOf('archival_object_') === 0;
  }

  #getSelectedNode() {
    if (!this.treeContainerEl) return null;

    return this.treeContainerEl.querySelector('.node.selected');
  }

  /**
   * Whether the current tree selection is a non-root row.
   * @returns {boolean}
   */
  #hasNonRootSelection() {
    if (!this.treeContainerEl) return false;

    return !!this.treeContainerEl.querySelector('li.node.selected:not(.root)');
  }

  /**
   * @param {boolean} enabled
   * @returns {string}
   */
  #moveOptionDisabledAttrs(enabled) {
    if (enabled) return '';

    return ' disabled aria-disabled="true"';
  }

  #renderMoveMenu() {
    if (!this.toolbarEl) return;

    const menuEl = this.toolbarEl.querySelector('.js-itree-toolbar-move-menu');
    if (!menuEl) return;

    const node = this.#getMoveContextNode();
    const parentList = node ? node.parentElement : null;
    const siblingsAtLevel =
      node && parentList
        ? Array.prototype.filter.call(parentList.children, function (child) {
            return child.matches('li.node') && child !== node;
          })
        : [];

    const prevSibling = node ? node.previousElementSibling : null;
    const nextSibling = node ? node.nextElementSibling : null;
    const level = node ? this.#getNodeLevel(node) : 0;
    const canMoveUp = !!(prevSibling && prevSibling.matches('li.node'));
    const canMoveDown = !!(nextSibling && nextSibling.matches('li.node'));
    const canMoveUpLevel = level > 1;
    const canMoveDownInto = siblingsAtLevel.length > 0;
    const siblingsMenuItems = node
      ? this.#siblingsForDownIntoMenu(node)
          .map(sibling => {
            const titleEl = sibling.querySelector(
              '.node-column[data-column="title"]'
            );
            const title = titleEl
              ? titleEl.textContent.trim()
              : sibling.id || '';
            return (
              '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="down-into" data-target-node-id="' +
              sibling.id +
              '">' +
              title +
              '</button></li>'
            );
          })
          .join('')
      : '';
    const downIntoToggleAttrs = canMoveDownInto
      ? ' data-toggle="dropdown"'
      : '';
    const menuParts = [
      '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="up-level"' +
        this.#moveOptionDisabledAttrs(canMoveUpLevel) +
        '>' +
        this.#translate('actions.move_up_a_level', 'Up a Level') +
        '</button></li>',
      '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="up"' +
        this.#moveOptionDisabledAttrs(canMoveUp) +
        '>' +
        this.#translate('actions.move_up', 'Up') +
        '</button></li>',
      '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="down"' +
        this.#moveOptionDisabledAttrs(canMoveDown) +
        '>' +
        this.#translate('actions.move_down', 'Down') +
        '</button></li>',
      '<li class="dropdown-submenu dropdown-item p-0">' +
        '<button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="down-into"' +
        downIntoToggleAttrs +
        this.#moveOptionDisabledAttrs(canMoveDownInto) +
        '>' +
        this.#translate('actions.move_down_into', 'Down Into...') +
        '</button>' +
        '<ul class="dropdown-menu move-node-into-menu">' +
        siblingsMenuItems +
        '</ul>' +
        '</li>',
    ];

    menuEl.innerHTML = menuParts.join('');
  }

  /**
   * Show only a limited number of siblings near the selected row in the Down Into submenu,
   * matching largetree behavior, likely for defense against large records.
   * @param {HTMLElement} node
   * @returns {HTMLElement[]}
   */
  #siblingsForDownIntoMenu(node) {
    const maxSiblings = 20;
    const half = Math.floor(maxSiblings / 2);
    const siblingsAbove = [];
    const siblingsBelow = [];

    let previous = node.previousElementSibling;
    while (previous) {
      if (
        previous.matches('li.node') &&
        !previous.classList.contains('js-itree-synthetic-new')
      ) {
        siblingsAbove.push(previous);
      }
      previous = previous.previousElementSibling;
    }

    let next = node.nextElementSibling;
    while (next) {
      if (
        next.matches('li.node') &&
        !next.classList.contains('js-itree-synthetic-new')
      ) {
        siblingsBelow.push(next);
      }
      next = next.nextElementSibling;
    }

    let selectedAbove = [];
    let selectedBelow = [];

    // Prefer a 50/50 split (half above, half below), then let the side with more
    // siblings fill any unused slots up to the max.
    if (siblingsAbove.length > half && siblingsBelow.length > half) {
      selectedAbove = siblingsAbove.slice(0, half);
      selectedBelow = siblingsBelow.slice(0, half);
    } else if (siblingsAbove.length > half) {
      selectedAbove = siblingsAbove.slice(
        0,
        maxSiblings - siblingsBelow.length
      );
      selectedBelow = siblingsBelow;
    } else if (siblingsBelow.length > half) {
      selectedAbove = siblingsAbove;
      selectedBelow = siblingsBelow.slice(
        0,
        maxSiblings - siblingsAbove.length
      );
    } else {
      selectedAbove = siblingsAbove;
      selectedBelow = siblingsBelow;
    }

    return selectedAbove.reverse().concat(selectedBelow);
  }

  #getNodeLevel(node) {
    if (!node || !node.className) return 0;

    const match = (node.className || '').match(/indent-level-(\d+)/);
    if (!match) return 0;

    return parseInt(match[1], 10);
  }
}
