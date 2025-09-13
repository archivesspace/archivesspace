(function (exports) {
  class InfiniteTreeRecordPane {
    constructor() {
      this.container = document.querySelector('#infinite-tree-record-pane');

      this.isReadOnly =
        document.querySelector('#infinite-tree-component').dataset
          .isReadOnly === 'true';
      this.form = null;
      this.isDirty = false;

      // Respond to tree selection
      this.container.addEventListener('infiniteTree:nodeSelect', e => {
        this.loadRecord(e.detail.node);
      });

      // Respond to router requesting a submit (for dirty-guard Save flow)
      this.container.addEventListener(
        'infiniteTreeRouter:requestSubmit',
        () => {
          this.submitActiveForm();
        }
      );
    }

    /**
     * @param {HTMLElement} node - The tree node  corresponding to the record to load
     */
    async loadRecord(node) {
      let recordPath = AS.app_prefix(
        node.dataset.uri.split('/').slice(-2).join('/')
      ); // ie: /repositories/2/archival_objects/4 --> /archival_objects/4

      if (!this.isReadOnly) recordPath += '/edit';

      const url = recordPath + '?inline=true';

      this.#blockUI();

      try {
        const html = await this.#fetchRecordHtml(url);

        this.container.innerHTML = html;

        // Initialize Rails/ASpace behaviors first
        this.#initializeRecordForm();
        // Then watch the (potential) form for dirty/submit
        this.#bindForm();
      } catch (error) {
        this.container.appendChild(this.#errorMessageFragment(error));

        this.#setDirty(false);
      } finally {
        this.#unblockUI();
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
        } catch (e) {
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

        // Replace pane content with response HTML and re-bind
        this.container.innerHTML = html;

        this.#initializeRecordForm();

        this.#bindForm();

        // Heuristic: presence of .error indicates validation errors
        const hasError = this.container.querySelector('.error') !== null;

        if (response.ok && !hasError) {
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
        this.container.appendChild(this.#errorMessageFragment(error));

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
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.text();
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
     * @param {Error} error - The error object
     * @returns {DocumentFragment} - The error message fragment
     */
    #errorMessageFragment(error) {
      const errorFrag = new DocumentFragment();
      const errorTemplate = document
        .getElementById('infinite-tree-record-pane-error-template')
        .content.cloneNode(true);
      const errorSlot = errorTemplate.querySelector('pre');

      errorSlot.textContent = error.message;

      errorFrag.appendChild(errorTemplate);

      return errorFrag;
    }
  }

  exports.InfiniteTreeRecordPane = InfiniteTreeRecordPane;
})(window);
