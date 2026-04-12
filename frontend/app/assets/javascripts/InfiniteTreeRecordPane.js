//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRecordPane {
    constructor() {
      this.container = document.querySelector('#infinite-tree-record-pane');
      this.treeContainerEl = document.querySelector('#infinite-tree-container');

      this.isReadOnly =
        document.querySelector('#infinite-tree-component').dataset
          .isReadOnly === 'true';
      this.form = null;
      this.isDirty = false;
      /** @type {HTMLElement|null} Parent tree node when the pane shows archival_objects new_inline (for Cancel). */
      this._inlineCreateParentNode = null;

      // Respond to tree selection (skip when InfiniteTree already loaded this record and only syncs chrome)
      this.container.addEventListener('infiniteTree:nodeSelect', e => {
        if (e.detail && e.detail.suppressPaneReload) return;

        this.loadRecord(e.detail.node);
      });

      // Respond to router requesting a submit (for dirty-guard Save flow)
      this.container.addEventListener(
        'infiniteTreeRouter:requestSubmit',
        () => {
          this.submitActiveForm();
        }
      );

      this.container.addEventListener('infiniteTree:showRecordNotFound', () => {
        this.#showRecordNotFound();
      });

      if (this.treeContainerEl && !this.isReadOnly) {
        this.treeContainerEl.addEventListener(
          'infiniteTreeToolbar:addChildRequested',
          e => this.#onAddChildRequested(e)
        );
      }

      // Cancel on new_inline uses link_to :back; intercept for inline tree UX
      this.container.addEventListener(
        'click',
        e => this.#onCancelClick(e),
        true
      );
    }

    /**
     * @param {Event} e
     */
    #onAddChildRequested(e) {
      if (this.isReadOnly) return;

      const node =
        (e.detail && e.detail.node) ||
        (this.treeContainerEl &&
          this.treeContainerEl.querySelector('li.node.selected'));

      if (!node) return;

      this.#loadNewChildRecord(node);
    }

    /**
     * Query string for GET new child form: root scope + optional parent scope.
     * @param {string} rootUri
     * @param {{ type: string, id: string }} parentParts
     * @returns {URLSearchParams|null}
     */
    #buildNewChildQuery(rootUri, parentParts) {
      const rootMeta = InfiniteTreeIds.rootUriToParts(rootUri);
      if (!rootMeta || !parentParts) return null;

      const { type: rootType, id: rootId, childType } = rootMeta;

      // First slice: resource tree → new archival object only
      if (rootType !== 'resource' || childType !== 'archival_object') {
        return null;
      }

      const qs = new URLSearchParams({ inline: 'true' });

      if (parentParts.type === 'resource') {
        qs.set('resource_id', String(parentParts.id));
        return qs;
      }

      if (parentParts.type === 'archival_object') {
        qs.set('resource_id', String(rootId));
        qs.set('archival_object_id', String(parentParts.id));
        return qs;
      }

      return null;
    }

    /**
     * @param {string} childType - from InfiniteTreeIds.rootUriToParts(...).childType
     * @returns {string|null} path segment under app prefix, e.g. archival_objects/new
     */
    #newChildFormPath(childType) {
      if (childType === 'archival_object') return 'archival_objects/new';

      return null;
    }

    #dispatchShowSyntheticNewChild(parentNode) {
      if (!this.treeContainerEl) return;

      this.treeContainerEl.dispatchEvent(
        new CustomEvent('infiniteTree:showSyntheticNewChild', {
          bubbles: true,
          detail: { parentNode },
        })
      );
    }

    #dispatchRemoveSyntheticNewChild() {
      if (!this.treeContainerEl) return;

      this.treeContainerEl.dispatchEvent(
        new CustomEvent('infiniteTree:removeSyntheticNewChild', {
          bubbles: true,
        })
      );
    }

    /**
     * Load new child record form for the selected tree node (root or child record).
     * @param {HTMLElement} parentNode
     */
    async #loadNewChildRecord(parentNode) {
      const component = document.querySelector('#infinite-tree-component');
      const rootUri = component && component.dataset.rootUri;
      const uri = parentNode.getAttribute('data-uri');
      const parentParts = InfiniteTreeIds.uriToParts(uri);

      const qs = this.#buildNewChildQuery(rootUri, parentParts);
      const rootMeta = InfiniteTreeIds.rootUriToParts(rootUri);
      const path = rootMeta && this.#newChildFormPath(rootMeta.childType);

      if (!qs || !path) return;

      this._inlineCreateParentNode = parentNode;

      this.#dispatchShowSyntheticNewChild(parentNode);

      const url = `${AS.app_prefix(path)}?${qs.toString()}`;

      this.#blockUI();

      try {
        const html = await this.#fetchRecordHtml(url);

        this.#renderNewForm(html);
        this.#setDirty(true);
      } catch (error) {
        this._inlineCreateParentNode = null;

        this.#dispatchRemoveSyntheticNewChild();

        if (error.status === 404) {
          this.#showRecordNotFound();
        } else {
          this.container.appendChild(this.#loadErrorMessageFragment(error));

          this.#setDirty(false);
        }
      } finally {
        this.#unblockUI();
      }
    }

    /**
     * @param {Event} e
     */
    #onCancelClick(e) {
      const cancel = e.target.closest('.form-actions .btn-cancel');
      if (!cancel || !this.form || !this.form.contains(cancel)) return;

      if (
        !this.#isArchivalObjectCreateForm(this.form) ||
        !this._inlineCreateParentNode
      ) {
        return;
      }

      e.preventDefault();
      e.stopPropagation();

      const parent = this._inlineCreateParentNode;
      this._inlineCreateParentNode = null;

      void this.#restoreTreeSelectionAfterCancelNewChild(parent);
    }

    /**
     * Reload parent record from Cancel, then restore tree .selected (loadRecord alone does not select).
     */
    async #restoreTreeSelectionAfterCancelNewChild(parent) {
      await this.loadRecord(parent);

      this.#requestTreeSelectionSync(parent);
    }

    /**
     * After pane HTML matches `node`, restore tree .selected and toolbar (e.g. Add Child → Cancel).
     * @param {HTMLElement} node
     */
    #requestTreeSelectionSync(node) {
      if (!this.treeContainerEl || !node) return;

      if (node.classList.contains('js-itree-synthetic-new')) return;

      this.treeContainerEl.dispatchEvent(
        new CustomEvent('infiniteTree:syncTreeSelection', {
          bubbles: true,
          detail: { node },
        })
      );
    }

    /**
     * @param {HTMLElement} node - The tree node corresponding to the record to load
     */
    async loadRecord(node) {
      this._inlineCreateParentNode = null;

      if (this.treeContainerEl) {
        this.#dispatchRemoveSyntheticNewChild();
      }

      let recordPath = AS.app_prefix(
        node.dataset.uri.split('/').slice(-2).join('/')
      ); // ie: /repositories/2/archival_objects/4 --> /archival_objects/4

      if (!this.isReadOnly) recordPath += '/edit';

      const url = recordPath + '?inline=true';

      this.#blockUI();

      try {
        const html = await this.#fetchRecordHtml(url);

        this.#renderNewForm(html);
      } catch (error) {
        if (error.status === 404) {
          this.#showRecordNotFound();
        } else {
          this.container.appendChild(this.#loadErrorMessageFragment(error));

          this.#setDirty(false);
        }
      } finally {
        this.#unblockUI();
      }
    }

    /**
     * @param {HTMLFormElement} form
     * @returns {boolean}
     */
    #isArchivalObjectCreateForm(form) {
      return this.#isArchivalObjectCreateSubmission(form);
    }

    /**
     * True when the form POSTs to archival_objects#create (inline new record).
     * @param {HTMLFormElement} form
     * @returns {boolean}
     */
    #isArchivalObjectCreateSubmission(form) {
      const method = (form.getAttribute('method') || 'GET').toUpperCase();
      if (method !== 'POST') return false;

      const action = form.getAttribute('action');
      if (!action) return false;

      try {
        const path = new URL(action, window.location.origin).pathname.replace(
          /\/$/,
          ''
        );

        return /\/archival_objects$/.test(path);
      } catch {
        return false;
      }
    }

    /**
     * Binds to the active form in the record pane (if any) and sets up dirty tracking and AJAX submit
     */
    #bindForm() {
      this.form = this.container.querySelector('form');

      if (!this.form || this.isReadOnly) {
        // No form present or read-only page; ensure clean state
        this.#setDirty(false);

        return;
      }

      // Start clean on load
      this.#setDirty(false);

      // Track changes to mark dirty (capture at the form level for robustness)
      const markDirty = () => this.#setDirty(true);

      this.form.addEventListener('change', markDirty, true);
      this.form.addEventListener('input', markDirty, true);

      // Also listen for legacy jQuery-based form change event used across the app
      // Some components emit formchanged.aspace on the document with the $form as an argument
      // Reset any prior namespaced handler to avoid duplicates after pane re-renders
      $(document).off('formchanged.aspace.infiniteTreePane');
      $(document).on('formchanged.aspace.infiniteTreePane', (_event, $ctx) => {
        try {
          const ctxEl = $ctx && $ctx.length ? $ctx[0] : null;
          if (!ctxEl || ctxEl === this.form || this.form.contains(ctxEl)) {
            markDirty();
          }
        } catch {
          // Fallback: mark dirty if we can't safely inspect context
          markDirty();
        }
      });

      // Keep listening directly on the form too (in case emitters target the form element)
      $(this.form).on('formchanged.aspace', markDirty);

      // Intercept normal form submit to keep interaction inline
      this.form.addEventListener('submit', e => {
        e.preventDefault();
        e.stopPropagation();

        this.submitActiveForm();
      });
    }

    /**
     * Programmatically submit the current form via fetch and emit result events
     */
    async submitActiveForm() {
      if (!this.form) return;

      const submitButton = this.form.querySelector('.btn-primary');

      if (submitButton) submitButton.setAttribute('disabled', 'disabled');

      const isCreateSubmission = this.#isArchivalObjectCreateSubmission(
        this.form
      );

      // Prepare FormData and include inline=true (to receive partial HTML)
      const formData = new FormData(this.form);

      formData.append('inline', 'true');

      const action = this.form.getAttribute('action');
      const method = (this.form.getAttribute('method') || 'POST').toUpperCase();

      // Notify start
      this.#dispatch('infiniteTreeRecordPane:submitStart', {});

      try {
        const response = await fetch(action, {
          method,
          body: formData,
          headers: {
            Accept: 'text/html',
          },
        });

        const html = await response.text();

        this.#renderNewForm(html);

        const hasError = this.container.querySelector('.error') !== null;

        if (response.ok && !hasError) {
          this._inlineCreateParentNode = null;

          this.#setDirty(false);

          // Try to extract the saved record URI from the updated pane (common hidden field id="uri")
          let savedUri = null;
          const uriInput = this.container.querySelector('#uri');

          if (uriInput && uriInput.value) savedUri = uriInput.value;

          // Unblock UI before firing success events to prevent race condition
          // with redisplayAndShow triggering loadRecord while pane is still blocked
          this.#unblockUI();

          if (submitButton) submitButton.removeAttribute('disabled');

          this.#dispatch('infiniteTreeRecordPane:submitSuccess', {
            uri: savedUri,
            created: isCreateSubmission,
          });

          this.#dispatch('infiniteTreeRecordPane:submitted', { success: true });
        } else {
          this.#setDirty(true);

          this.#dispatch('infiniteTreeRecordPane:submitError', {
            status: response.status,
          });

          this.#dispatch('infiniteTreeRecordPane:submitted', {
            success: false,
          });
        }
      } catch (error) {
        // Show an error banner and emit error
        this.container.appendChild(this.#loadErrorMessageFragment(error));

        this.#setDirty(true);

        this.#dispatch('infiniteTreeRecordPane:submitError', {
          error: String(error),
        });

        this.#dispatch('infiniteTreeRecordPane:submitted', { success: false });
      } finally {
        // Only unblock and re-enable if not already done in success case
        if (this.container.classList.contains('blocked')) {
          this.#unblockUI();
        }

        if (submitButton && submitButton.hasAttribute('disabled')) {
          submitButton.removeAttribute('disabled');
        }
      }
    }

    #setDirty(value) {
      const changed = this.isDirty !== value;

      this.isDirty = value;

      if (changed) {
        if (this.isDirty) {
          this.#dispatch('infiniteTreeRecordPane:dirty', {});
        } else {
          this.#dispatch('infiniteTreeRecordPane:clean', {});
        }
      }
    }

    #dispatch(type, detail) {
      this.container.dispatchEvent(new CustomEvent(type, { detail }));
    }

    #blockUI() {
      this.container.classList.add('blocked');
    }

    #unblockUI() {
      this.container.classList.remove('blocked');
    }

    /**
     * Returns HTML fetched from the given URL
     * @param {string} url - The URL to load
     * @returns {Promise<string>} - The HTML content
     */
    async #fetchRecordHtml(url) {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          Accept: 'text/html',
        },
      });

      if (!response.ok) {
        if (response.status === 404) {
          const err = new Error('Record not found');

          err.status = 404;

          throw err;
        }

        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.text();
    }

    /**
     * Renders form HTML into the pane and wires it up
     */
    #renderNewForm(html) {
      this.container.innerHTML = html;

      this.#initializeRecordForm();

      this.#bindForm();
    }

    /**
     * Use the jQuery event pattern for compatibility with the broader form initialization system
     */
    #initializeRecordForm() {
      $(document).triggerHandler('loadedrecordform.aspace', [
        $(this.container),
      ]);
    }

    /**
     * Builds a fragment for non-404 fetch errors
     * @param {Error} error - The error object
     * @returns {DocumentFragment} - The error message fragment
     */
    #loadErrorMessageFragment(error) {
      const errorFrag = new DocumentFragment();
      const errorTemplate = document
        .getElementById('infinite-tree-record-pane-load-error-template')
        .content.cloneNode(true);
      const errorSlot = errorTemplate.querySelector('pre');

      errorSlot.textContent = error.message;

      errorFrag.appendChild(errorTemplate);

      return errorFrag;
    }

    /**
     * Shows the Record Not Found alert
     */
    #showRecordNotFound() {
      const template = document.getElementById(
        'infinite-tree-record-pane-record-not-found-template'
      );

      this.container.replaceChildren(template.content.cloneNode(true));

      this.#setDirty(false);
    }
  }

  exports.InfiniteTreeRecordPane = InfiniteTreeRecordPane;
})(window);
