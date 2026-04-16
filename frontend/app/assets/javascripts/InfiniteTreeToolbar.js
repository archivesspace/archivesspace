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
    this.hasCutSelection = false;
    this.dropBehavior = this.#loadDropBehavior();

    this.#bindEvents();
    this.#syncDropBehaviorInputs();
    this.#applyReorderState();
    this.#applySelectionState();

    if (this.treeContainerEl) {
      this.treeContainerEl.addEventListener(
        'infiniteTree:autoExpandBusy',
        this.#onAutoExpandBusy.bind(this)
      );

      this.treeContainerEl.addEventListener(
        'infiniteTreeToolbar:cutStateChanged',
        this.#onCutStateChanged.bind(this)
      );
    }
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

    this.toolbarEl.addEventListener('change', event => {
      const radio = event.target;

      if (
        radio.name === 'drop-behavior' &&
        radio.checked &&
        !radio.closest('.disabled')
      ) {
        this.dropBehavior = radio.value;
        this.#persistDropBehavior(this.dropBehavior);
        this.#emitSimpleEvent('infiniteTreeToolbar:dropBehaviorChanged', {
          dropBehavior: this.dropBehavior,
        });
      }
    });
  }

  #handleSelectionChanged(e) {
    this.currentNode = e.detail && e.detail.node ? e.detail.node : null;
    this.#applySelectionState();
  }

  #applySelectionState() {
    const selectedNode = this.currentNode || this.#getSelectedNode();
    const selectedIsRoot = !!(
      selectedNode && selectedNode.classList.contains('root')
    );
    const canCut = this.reorderMode && !!selectedNode && !selectedIsRoot;
    const cutBtn = this.toolbarEl.querySelector('.js-itree-toolbar-cut');

    if (cutBtn) {
      this.#setButtonDisabled(cutBtn, !canCut);
    }

    const isArchivalObjectSelected = this.#isArchivalObjectSelected();
    const showMove = this.reorderMode && isArchivalObjectSelected;
    const moveToggle = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-toggle'
    );

    if (moveToggle) {
      if (!showMove) {
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
      moveGroup.style.display = showMove ? '' : 'none';
    }

    if (showMove) {
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

    if (btn) {
      btn.classList.toggle('btn-success', this.expandAllMode);
      btn.textContent = this.expandAllMode
        ? this.#translate('actions.expand_tree_mode_off', 'Disable Auto-Expand')
        : this.#translate('actions.expand_tree_mode_on', 'Auto-Expand All');
    }

    this.#emitSimpleEvent('infiniteTreeToolbar:expandModeChanged', {
      enabled: this.expandAllMode,
    });
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

  #onCutStateChanged(e) {
    this.hasCutSelection = !!(e.detail && e.detail.hasCut);
    this.#applyCutPasteState();
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

  #loadDropBehavior() {
    try {
      const stored = window.localStorage.getItem('AS_Drop_Behavior');
      if (stored === 'before' || stored === 'into' || stored === 'after') {
        return stored;
      }
    } catch (e) {
      // ignore storage errors
    }

    return 'before';
  }

  #persistDropBehavior(value) {
    try {
      window.localStorage.setItem('AS_Drop_Behavior', value);
    } catch (e) {
      // ignore storage errors
    }
  }

  #translate(key, fallback) {
    if (window.AS && window.AS.I18n && typeof window.AS.I18n.t === 'function') {
      return window.AS.I18n.t(key);
    }

    return fallback;
  }

  #syncDropBehaviorInputs() {
    if (!this.toolbarEl) return;

    const selector = 'input[type="radio"][name="drop-behavior"]';
    const radios = this.toolbarEl.querySelectorAll(selector);

    radios.forEach(radio => {
      radio.checked = radio.value === this.dropBehavior;
    });
  }

  #applyReorderState() {
    if (!this.toolbarEl) return;

    const showReorderControls = this.reorderMode;
    const showNonReorderControls = !this.reorderMode;
    const cutPasteGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-cut-paste-group'
    );
    const dropBehaviorGroup = this.toolbarEl.querySelector(
      '.js-itree-toolbar-drop-behavior-group'
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

    if (dropBehaviorGroup) {
      dropBehaviorGroup.style.display = showReorderControls ? 'flex' : 'none';
    }

    if (expandGroup) {
      expandGroup.style.display = showNonReorderControls ? '' : 'none';
    }

    if (primaryActionsGroup) {
      primaryActionsGroup.style.display = showNonReorderControls ? '' : 'none';
    }

    if (this.treeContainerEl) {
      this.treeContainerEl.classList.toggle(
        'reorder-enabled',
        showReorderControls
      );
    }

    if (!showReorderControls) {
      this.hasCutSelection = false;
    }

    this.#applyCutPasteState();
  }

  #applyCutPasteState() {
    const pasteBtn = this.toolbarEl.querySelector('.js-itree-toolbar-paste');

    if (pasteBtn) {
      const enablePaste = this.reorderMode && this.hasCutSelection;

      this.#setButtonDisabled(pasteBtn, !enablePaste);
    }
  }

  #setButtonDisabled(buttonEl, disabled) {
    if (disabled) {
      buttonEl.classList.add('disabled');
      buttonEl.setAttribute('aria-disabled', 'true');
    } else {
      buttonEl.classList.remove('disabled');
      buttonEl.removeAttribute('aria-disabled');
    }
  }

  #isArchivalObjectSelected() {
    const node = this.currentNode || this.#getSelectedNode();
    if (!node) return false;

    if (node.classList.contains('root')) return false;

    return (node.id || '').indexOf('archival_object_') === 0;
  }

  #getSelectedNode() {
    if (!this.treeContainerEl) return null;

    return this.treeContainerEl.querySelector('.node.selected');
  }

  #renderMoveMenu() {
    if (!this.toolbarEl) return;

    const menuEl = this.toolbarEl.querySelector('.js-itree-toolbar-move-menu');
    if (!menuEl) return;

    const node = this.currentNode || this.#getSelectedNode();
    if (!node) {
      menuEl.innerHTML = '';
      return;
    }

    const parentList = node.parentElement;
    const siblingsAtLevel = parentList
      ? Array.prototype.filter.call(parentList.children, function (child) {
          return child.matches('li.node') && child !== node;
        })
      : [];

    const prevSibling = node.previousElementSibling;
    const nextSibling = node.nextElementSibling;
    const level = this.#getNodeLevel(node);
    const canMoveUp = !!(prevSibling && prevSibling.matches('li.node'));
    const canMoveDown = !!(nextSibling && nextSibling.matches('li.node'));
    const canMoveUpLevel = level > 1;
    const siblingsMenuItems = siblingsAtLevel
      .map(sibling => {
        const titleEl = sibling.querySelector(
          '.node-column[data-column="title"]'
        );
        const title = titleEl ? titleEl.textContent.trim() : sibling.id || '';
        return (
          '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="down-into" data-target-node-id="' +
          sibling.id +
          '">' +
          title +
          '</button></li>'
        );
      })
      .join('');
    const menuParts = [];

    if (canMoveUpLevel) {
      menuParts.push(
        '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="up-level">' +
          this.#translate('actions.move_up_a_level', 'Up a Level') +
          '</button></li>'
      );
    }

    if (canMoveUp) {
      menuParts.push(
        '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="up">' +
          this.#translate('actions.move_up', 'Up') +
          '</button></li>'
      );
    }

    if (canMoveDown) {
      menuParts.push(
        '<li><button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-move-action="down">' +
          this.#translate('actions.move_down', 'Down') +
          '</button></li>'
      );
    }

    if (siblingsAtLevel.length > 0) {
      menuParts.push(
        '<li class="dropdown-submenu dropdown-item p-0">' +
          '<button type="button" class="btn btn-sm rounded-0 dropdown-item cursor-default js-itree-toolbar-move-option" data-toggle="dropdown" data-move-action="down-into">' +
          this.#translate('actions.move_down_into', 'Down Into...') +
          '</button>' +
          '<ul class="dropdown-menu move-node-into-menu">' +
          siblingsMenuItems +
          '</ul>' +
          '</li>'
      );
    }

    menuEl.innerHTML = menuParts.join('');
  }

  #getNodeLevel(node) {
    if (!node || !node.className) return 0;

    const match = (node.className || '').match(/indent-level-(\d+)/);
    if (!match) return 0;

    return parseInt(match[1], 10);
  }
}
