//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRouter {
    /**
     * @constructor
     * @param {Object} i18n - The i18n object for use in a non .js.erb file
     * @param {string} i18n.saveChangesTitle - The title of the save changes modal
     */
    constructor(i18n) {
      const { rootUri, isReadOnly } = document.querySelector(
        '#infinite-tree-component'
      ).dataset;

      this.currentHash = window.location.hash;
      this.treeContainer = document.querySelector('#infinite-tree-container');
      this.recordPaneEl = document.querySelector('#infinite-tree-record-pane');

      this.rootUri = rootUri;
      this.isReadOnly = isReadOnly === 'true';
      this.i18n = i18n;
      this.inflight = null;
      this.isDirty = false;
      this._ignoreHashChange = false;
      this._pendingHash = null;
      this._pendingSavedUri = null;
      this._pendingTransaction = null;

      this.addListeners();

      this.init();
    }

    addListeners() {
      // Track dirty/clean events from the record pane
      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:dirty', () => {
        this.isDirty = true;
      });

      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:clean', () => {
        this.isDirty = false;
      });

      // React to submit results during dirty guard Save
      this.recordPaneEl.addEventListener(
        'infiniteTreeRecordPane:submitSuccess',
        e => {
          const target = this._pendingHash;
          const { uri: savedUri } = e.detail || {};

          // Store transaction state for completion handler
          this._pendingTransaction = {
            target: target,
            savedUri: savedUri,
          };

          // Clear pending hash now that we've captured it
          this._pendingHash = null;
          this._pendingSavedUri = null;
          this.isDirty = false;

          // Start the refresh process
          if (savedUri) {
            this.treeContainer.dispatchEvent(
              new CustomEvent('infiniteTreeRouter:refreshNode', {
                detail: { uri: savedUri },
              })
            );
          } else {
            // No refresh needed, complete transaction immediately
            this.#completeTransaction();
          }
        }
      );

      // Listen for refresh completion to finish the transaction
      this.treeContainer.addEventListener(
        'infiniteTree:refreshNodeComplete',
        () => {
          // Only handle if this is part of a pending transaction
          if (this._pendingTransaction) {
            this.#completeTransaction();
          }
        }
      );

      this.recordPaneEl.addEventListener(
        'infiniteTreeRecordPane:submitError',
        () => {}
        // Leave the user on the current record; no further action}
      );

      // Intercept title clicks
      this.treeContainer.addEventListener('infiniteTree:titleClick', e => {
        const { node } = e.detail;
        const target = InfiniteTreeIds.uriToLocationHash(node.dataset.uri);

        if (this.isReadOnly || !this.isDirty) {
          // Fast path: clean — just set the hash and let the hashchange handler dispatch
          this.setHash(target);
        } else {
          // Guarded path: prevent default behavior altogether
          e.preventDefault();
          e.stopPropagation();

          this.#openDirtyModal(target);
        }
      });

      // Intercept browser hash changes (back/forward/manual edits)
      window.addEventListener('hashchange', () => this.#onHashChange());
    }

    init() {
      if (this.currentHash === '') {
        const hash = InfiniteTreeIds.treeLinkUrl(this.rootUri);

        // Set the hash and rely on hashchange to dispatch the first navigation
        this.setHash(hash);
      } else {
        // No hashchange will occur; dispatch directly
        this.dispatchNodeSelect(this.currentHash);
      }
    }

    #onHashChange() {
      if (this._ignoreHashChange) {
        this._ignoreHashChange = false;

        return;
      }

      const newHash = window.location.hash;

      if (this.isReadOnly || !this.isDirty) {
        // Navigation allowed
        this.currentHash = newHash;

        this.dispatchNodeSelect(newHash);
      } else {
        // Revert visual hash and show guard
        const target = newHash;

        this._ignoreHashChange = true;

        window.location.hash = this.currentHash;

        this.#openDirtyModal(target);
      }
    }

    #openDirtyModal(targetHash) {
      // Save target for later
      this._pendingHash = targetHash;

      // Open the existing Save Changes modal template
      AS.openCustomModal(
        'saveYourChangesModal',
        this.i18n.saveChangesTitle,
        AS.renderTemplate('save_changes_modal_template')
      );

      // Hook up modal actions
      $('#saveChangesButton', '#saveYourChangesModal').on('click', () => {
        $('.btn', '#saveYourChangesModal').addClass('disabled');
        // Capture the currently selected node's URI in case the form doesn't provide one
        try {
          const selectedNode =
            this.treeContainer.querySelector('li.node.selected');

          this._pendingSavedUri = selectedNode
            ? selectedNode.getAttribute('data-uri')
            : null;
        } catch (e) {
          this._pendingSavedUri = null;
        }
        // Ask record pane to submit the form
        this.recordPaneEl.dispatchEvent(
          new CustomEvent('infiniteTreeRouter:requestSubmit')
        );
      });

      $('#dismissChangesButton', '#saveYourChangesModal').on('click', () => {
        // Discard changes and proceed
        this.isDirty = false;

        this.#proceedToHash(this._pendingHash);

        this._pendingHash = null;

        $('#saveYourChangesModal').modal('hide');
      });

      $('.btn-cancel', '#saveYourChangesModal').on('click', () => {
        // Cancel: do nothing
        this._pendingHash = null;

        $('#saveYourChangesModal').modal('hide');
      });
    }

    #proceedToHash(hash) {
      if (!hash) return;

      this.setHash(hash);

      this.dispatchNodeSelect(window.location.hash);
    }

    dispatchNodeSelect(hash) {
      const prefixedHash = hash && hash.startsWith('#') ? hash : `#${hash}`;

      this.treeContainer.dispatchEvent(
        new CustomEvent('infiniteTreeRouter:nodeSelect', {
          detail: {
            targetHash: prefixedHash,
          },
        })
      );
    }

    setHash(hash) {
      const normalized = this.#normalizeHash(hash);

      window.location.hash = normalized;

      this.currentHash = window.location.hash;
    }

    /**
     * Normalizes hash by removing # prefix if present
     * @param {string} hash - The hash string to normalize
     * @returns {string} Normalized hash without #
     * @private
     */
    #normalizeHash(hash) {
      return hash.replace(/^#/, '');
    }

    /**
     * Completes the save transaction by closing modal and navigating to target
     */
    #completeTransaction() {
      if (!this._pendingTransaction) return;

      const { target } = this._pendingTransaction;

      // Close the modal now that everything is complete
      $('#saveYourChangesModal').modal('hide');

      // Navigate to the pending target if there is one
      if (target) {
        this.setHash(target);
      }

      // Clear transaction state
      this._pendingTransaction = null;
    }
  }

  exports.InfiniteTreeRouter = InfiniteTreeRouter;
})(window);
