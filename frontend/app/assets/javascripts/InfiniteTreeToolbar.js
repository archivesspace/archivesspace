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
    this.#applyCurrentNodeState();

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

    if (option.hasAttribute('disabled')) {
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
        'infiniteTree:currentNodeChanged',
        this.#handleCurrentNodeChanged.bind(this)
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
        InfiniteTreeMultiSelection.EVENT_CHANGED,
        this.#onSelectionChanged.bind(this)
      );
      this.treeContainerEl.addEventListener(
        InfiniteTreeMultiSelection.EVENT_CLEARED,
        this.#onSelectionCleared.bind(this)
      );
      this.treeContainerEl.addEventListener(
        'infiniteTree:redisplayAndReopenComplete',
        this.#onRedisplayAndReopenComplete.bind(this)
      );
      this.treeContainerEl.addEventListener(
        'infiniteTree:redisplayAndShowComplete',
        this.#onRedisplayAndShowComplete.bind(this)
      );
    }

    this.toolbarEl.addEventListener('click', event => {
      const target = event.target.closest('[data-itree-action]');
      if (!target || this.#isControlDisabled(target)) return;

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

  #handleCurrentNodeChanged(e) {
    this.currentNode = e.detail && e.detail.node ? e.detail.node : null;
    this.#applyCurrentNodeState();
    if (this.reorderMode) {
      this.#applyCutPasteState();
    }
  }

  #applyCurrentNodeState() {
    if (!this.toolbarEl) return;

    const isArchivalObjectCurrent = this.#isArchivalObjectCurrent();
    const moveEnabled = this.reorderMode && this.#hasNonRootCurrentNode();
    const moveToggle = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-toggle'
    );

    this.#setControlEnabled(moveToggle, moveEnabled);

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
      siblingBtn.style.display = isArchivalObjectCurrent ? '' : 'none';
    }

    const duplicateBtn = this.toolbarEl.querySelector(
      '.js-itree-toolbar-add-duplicate'
    );
    if (duplicateBtn) {
      duplicateBtn.style.display = isArchivalObjectCurrent ? '' : 'none';
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
      this.#setControlEnabled(btn, !this.isDirty);
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
    this.#applyCurrentNodeState();
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
      this.#applyCurrentNodeState();
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
    this.#applyCurrentNodeState();
    this.#applyCutPasteState();
  }

  #onRedisplayAndShowComplete() {
    if (this.reorderMode) return;

    this.#syncCurrentNodeFromLiveTree();
    this.#applyCurrentNodeState();
  }

  /**
   * Live `.current` tree row, excluding inline-create synthetic placeholders.
   * After redisplay, cached `currentNode` may reference detached DOM.
   * @returns {HTMLElement|null}
   */
  #getLiveCurrentNode() {
    if (!this.treeContainerEl) return null;

    const current = this.treeContainerEl.querySelector(
      'li.node.current:not(.js-itree-synthetic-new)'
    );

    if (current && current.isConnected) {
      return current;
    }

    return null;
  }

  #syncCurrentNodeFromLiveTree() {
    const node = this.#getLiveCurrentNode();
    if (node) {
      this.currentNode = node;
    }
  }

  /**
   * Resolve the live tree row that Move menu options apply to. Move always
   * targets the `.current` node. After reorder redisplay, cached `currentNode`
   * can reference detached DOM, so read the current node from the tree.
   * @returns {HTMLElement|null}
   */
  #getMoveContextNode() {
    const current = this.#getLiveCurrentNode();
    if (current && !current.classList.contains('root')) {
      return current;
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

    this.#setControlEnabled(expandBtn, !busy);
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

    this.#syncCurrentNodeFromLiveTree();

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
    const cutEnabled = this.reorderMode && this.#hasEligibleCutNode();
    this.#setControlEnabled(cutBtn, cutEnabled);

    const pasteBtn = this.toolbarEl.querySelector('.js-itree-toolbar-paste');
    if (!pasteBtn) return;

    const pasteEnabled =
      this.reorderMode && this.cutActive && this.#hasEligiblePasteTarget();
    this.#setControlEnabled(pasteBtn, pasteEnabled);
  }

  /**
   * Whether at least one row can be cut: multiselected non-root rows, or a
   * current non-root row when no multiselected rows exist.
   * @returns {boolean}
   */
  #hasEligibleCutNode() {
    if (!this.treeContainerEl) return false;

    const multiselected = this.treeContainerEl.querySelectorAll(
      'li.node.multiselected:not(.root)'
    );
    if (multiselected.length > 0) return true;

    const current = this.treeContainerEl.querySelector(
      'li.node.current:not(.root)'
    );
    return !!current;
  }

  /**
   * Whether a valid paste destination exists: the `.current` row
   * that is not `.cut`, including root.
   * @returns {boolean}
   */
  #hasEligiblePasteTarget() {
    if (!this.treeContainerEl) return false;

    return !!this.treeContainerEl.querySelector('li.node.current:not(.cut)');
  }

  #isArchivalObjectCurrent() {
    const node = this.reorderMode
      ? this.#getMoveContextNode()
      : this.currentNode || this.#getCurrentNode();
    if (!node) return false;

    if (node.classList.contains('root')) return false;

    return (node.id || '').indexOf('archival_object_') === 0;
  }

  #getCurrentNode() {
    if (!this.treeContainerEl) return null;

    return this.treeContainerEl.querySelector('.node.current');
  }

  /**
   * Whether the current tree node is a non-root row.
   * @returns {boolean}
   */
  #hasNonRootCurrentNode() {
    if (!this.treeContainerEl) return false;

    return !!this.treeContainerEl.querySelector('li.node.current:not(.root)');
  }

  /**
   * @param {HTMLElement|null} el
   * @returns {boolean}
   */
  #isControlDisabled(el) {
    return (
      !!el &&
      (el.classList.contains('disabled') ||
        el.hasAttribute('disabled') ||
        el.getAttribute('aria-disabled') === 'true')
    );
  }

  /**
   * Toggle enabled state. Native buttons get disabled attr; links get aria-disabled.
   * @param {HTMLElement|null} el
   * @param {boolean} enabled
   */
  #setControlEnabled(el, enabled) {
    if (!el) return;

    const isNativeControl = el.matches('button, input, select, textarea');

    if (enabled) {
      el.classList.remove('disabled');
      el.removeAttribute('disabled');
      el.removeAttribute('aria-disabled');
      return;
    }

    el.classList.add('disabled');
    if (isNativeControl) {
      el.setAttribute('disabled', 'disabled');
    } else {
      el.setAttribute('aria-disabled', 'true');
    }
  }

  #createMoveMenuItem(action, enabled, label) {
    const li = document.createElement('li');
    li.appendChild(this.#createMoveMenuButton(action, enabled, label));
    return li;
  }

  #createMoveMenuButton(action, enabled, label) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className =
      'btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option';
    button.setAttribute('data-move-action', action);
    if (!enabled) {
      button.setAttribute('disabled', 'disabled');
    }
    button.textContent = label;
    return button;
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

    menuEl.innerHTML = '';

    menuEl.appendChild(
      this.#createMoveMenuItem(
        'up-level',
        canMoveUpLevel,
        this.#translate('actions.move_up_a_level', 'Up a Level')
      )
    );
    menuEl.appendChild(
      this.#createMoveMenuItem(
        'up',
        canMoveUp,
        this.#translate('actions.move_up', 'Up')
      )
    );
    menuEl.appendChild(
      this.#createMoveMenuItem(
        'down',
        canMoveDown,
        this.#translate('actions.move_down', 'Down')
      )
    );

    const downIntoLi = document.createElement('li');
    downIntoLi.className = 'dropdown-submenu dropdown-item p-0';

    const downIntoButton = this.#createMoveMenuButton(
      'down-into',
      canMoveDownInto,
      this.#translate('actions.move_down_into', 'Down Into...')
    );
    if (canMoveDownInto) {
      downIntoButton.setAttribute('data-toggle', 'dropdown');
    }
    downIntoLi.appendChild(downIntoButton);

    const submenu = document.createElement('ul');
    submenu.className = 'dropdown-menu move-node-into-menu';

    if (node) {
      this.#siblingsForDownIntoMenu(node).forEach(sibling => {
        const titleEl = sibling.querySelector(
          '.node-column[data-column="title"]'
        );
        const title = titleEl ? titleEl.textContent.trim() : sibling.id || '';
        const submenuButton = this.#createMoveMenuButton(
          'down-into',
          true,
          title
        );
        submenuButton.setAttribute('data-target-node-id', sibling.id);
        const submenuLi = document.createElement('li');
        submenuLi.appendChild(submenuButton);
        submenu.appendChild(submenuLi);
      });
    }

    downIntoLi.appendChild(submenu);
    menuEl.appendChild(downIntoLi);
  }

  /**
   * Show only a limited number of siblings near the current row in the Down Into submenu,
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
