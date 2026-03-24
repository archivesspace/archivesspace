class InfiniteTreeToolbar {
  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.toolbarEl = this.componentEl.querySelector('#infinite-tree-toolbar');
    this.treeContainerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    this.recordPaneEl = this.componentEl.querySelector(
      '[data-infinite-tree-record-pane]'
    );

    this.readOnly =
      this.componentEl.getAttribute('data-is-read-only') === 'true';
    this.rootUri = this.componentEl.getAttribute('data-root-uri');
    this.rootType = this.componentEl.querySelector('[data-record-type]')
      ? this.componentEl
          .querySelector('[data-record-type]')
          .getAttribute('data-record-type')
      : null;

    this.currentNode = null;
    this.isDirty = false;
    this.reorderMode = false;
    this.expandAllMode = false;
    this.dropBehavior = this.#loadDropBehavior();

    this.#bindEvents();
    this.#syncDropBehaviorInputs();
  }

  #bindEvents() {
    if (!this.toolbarEl) return;

    if (this.treeContainerEl) {
      this.treeContainerEl.addEventListener(
        'infiniteTree:selectionChanged',
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
        case 'transfer':
          this.#emitContextualEvent('infiniteTreeToolbar:transferRequested');
          break;
        case 'expand-mode':
          this.#onExpandModeToggle(event, target);
          break;
        case 'collapse-tree':
          this.#emitSimpleEvent('infiniteTreeToolbar:collapseTreeRequested');
          break;
        case 'finish-editing':
          this.#onFinishEditingClick(event, target);
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
    if (!this.toolbarEl) return;

    const isRoot =
      this.currentNode && this.currentNode.classList.contains('root');

    const moveToggle = this.toolbarEl.querySelector(
      '.js-itree-toolbar-move-toggle'
    );
    if (moveToggle) {
      if (isRoot) {
        moveToggle.classList.add('disabled');
        moveToggle.setAttribute('aria-disabled', 'true');
      } else {
        moveToggle.classList.remove('disabled');
        moveToggle.removeAttribute('aria-disabled');
      }
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
      '.js-itree-toolbar-transfer,' +
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
    btn.classList.toggle('btn-success', this.reorderMode);
    btn.classList.toggle('active', this.reorderMode);

    btn.textContent = this.reorderMode
      ? AS.I18n.t('actions.reorder_active')
      : AS.I18n.t('actions.enable_reorder');

    this.#emitSimpleEvent('infiniteTreeToolbar:reorderModeChanged', {
      enabled: this.reorderMode,
    });
  }

  #onExpandModeToggle(event, btn) {
    event.preventDefault();

    this.expandAllMode = !this.expandAllMode;
    btn.classList.toggle('btn-success', this.expandAllMode);

    btn.textContent = this.expandAllMode
      ? AS.I18n.t('actions.expand_tree_mode_off')
      : AS.I18n.t('actions.expand_tree_mode_on');

    this.#emitSimpleEvent('infiniteTreeToolbar:expandModeChanged', {
      enabled: this.expandAllMode,
    });
  }

  #onFinishEditingClick(event, btn) {
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

  #syncDropBehaviorInputs() {
    if (!this.toolbarEl) return;
    const selector = 'input[type="radio"][name="drop-behavior"]';
    const radios = this.toolbarEl.querySelectorAll(selector);
    radios.forEach(radio => {
      radio.checked = radio.value === this.dropBehavior;
    });
  }
}
