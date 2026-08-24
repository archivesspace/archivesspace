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
      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:dirty', () => {
        this.isDirty = true;
      });

      this.recordPaneEl.addEventListener('infiniteTreeRecordPane:clean', () => {
        this.isDirty = false;
      });

      // Respond to submit results during dirty guard Save
      this.recordPaneEl.addEventListener(
        'infiniteTreeRecordPane:submitSuccess',
        e => {
          const target = this._pendingHash;
          const { uri: savedUri, created, plusOne } = e.detail || {};

          // plusOne is set by InfiniteTreeRecordPane when the user clicked Save +1 on an
          // inline tree form (type="button" plus-one controls; see that module). Plain
          // Save and dirty-guard submits leave it false. Mirrors AjaxTree createPlusOne →
          // redisplayAndShow → add_new_after, but defers sibling form load until here.
          this._pendingTransaction = {
            target: target,
            savedUri: savedUri,
            created: !!created,
            plusOne: !!plusOne,
          };

          // Clear pending hash now that we've captured it
          this._pendingHash = null;
          this._pendingSavedUri = null;
          this.isDirty = false;

          if (!savedUri) {
            this.#completeTransaction();

            return;
          }

          if (created) {
            const newRecordHash = InfiniteTreeIds.treeLinkUrl(savedUri);

            if (target) {
              const pendingHash = target.startsWith('#')
                ? target
                : `#${target}`;

              this.#setHashSilently(pendingHash);

              this.treeContainer.dispatchEvent(
                new CustomEvent('infiniteTreeRouter:redisplayAndShow', {
                  detail: { targetHash: pendingHash, plusOne: !!plusOne },
                })
              );
            } else {
              this.#setHashSilently(newRecordHash);

              this.treeContainer.dispatchEvent(
                new CustomEvent('infiniteTreeRouter:redisplayAndShow', {
                  detail: { targetHash: newRecordHash, plusOne: !!plusOne },
                })
              );
            }
          } else {
            this.treeContainer.dispatchEvent(
              new CustomEvent('infiniteTreeRouter:refreshNode', {
                detail: { uri: savedUri },
              })
            );
          }
        }
      );

      // Listen for refresh completion to finish the transaction
      this.treeContainer.addEventListener(
        'infiniteTree:refreshNodeComplete',
        () => {
          if (this._pendingTransaction) {
            this.#completeTransaction();
          }
        }
      );

      this.treeContainer.addEventListener(
        'infiniteTree:redisplayAndShowComplete',
        () => {
          if (this._pendingTransaction) {
            const { savedUri, created, plusOne } = this._pendingTransaction;

            // Inline Save +1: open sibling new form after tree refresh (AjaxTree:
            // add_new_after in redisplayAndShow callback). plusOneAfterCreate runs before
            // completeTransaction so the record pane still has transaction context.
            if (created && plusOne && savedUri) {
              this.recordPaneEl.dispatchEvent(
                new CustomEvent('infiniteTreeRouter:plusOneAfterCreate', {
                  detail: { uri: savedUri },
                })
              );
            }

            this.#completeTransaction();
          }
        }
      );

      this.treeContainer.addEventListener(
        'infiniteTreeRouter:replaceHash',
        e => {
          const { targetHash } = e.detail || {};

          if (!targetHash) return;

          this.#setHashSilently(targetHash);

          // When the requested hash matches the URL hash (the common case from
          // reorder flows where we re-assert the currently-selected record),
          // no hashchange event fires and `_ignoreHashChange` would otherwise
          // stay stuck at true. Clear it after the current microtask so the
          // next user-initiated hashchange is processed normally.
          queueMicrotask(() => {
            this._ignoreHashChange = false;
          });
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
      if (this.currentHash === '' || !this.#isValidTreeHash(this.currentHash)) {
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

      // #new is the transient inline-create hash, accept it without dispatching nodeSelect.
      if (this.#isInlineCreateHash(newHash)) {
        this.currentHash = newHash;

        return;
      }

      if (!this.#isValidTreeHash(newHash)) {
        // Silently revert invalid hash to current hash
        this._ignoreHashChange = true;
        window.location.hash = this.currentHash;

        return;
      }

      if (this.isReadOnly || !this.isDirty) {
        // Navigation allowed
        this.currentHash = newHash;

        this.dispatchNodeSelect(newHash);
      } else {
        // Navigation not allowed, revert hash and show guard
        const target = newHash;

        this._ignoreHashChange = true;
        window.location.hash = this.currentHash;

        this.#openDirtyModal(target);
      }
    }

    #openDirtyModal(targetHash) {
      // Save target for later
      this._pendingHash = targetHash;

      AS.openCustomModal(
        'saveYourChangesModal',
        this.i18n.saveChangesTitle,
        AS.renderTemplate('save_changes_modal_template')
      );

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

        this.#requestFormSubmit();
      });

      $('#dismissChangesButton', '#saveYourChangesModal').on('click', () => {
        this.isDirty = false;

        this.#proceedToHash(this._pendingHash);

        this._pendingHash = null;

        $('#saveYourChangesModal').modal('hide');
      });

      $('.btn-cancel', '#saveYourChangesModal').on('click', () => {
        this._pendingHash = null;

        $('#saveYourChangesModal').modal('hide');
      });
    }

    #proceedToHash(hash) {
      if (!hash) return;

      this.setHash(hash);

      this.dispatchNodeSelect(window.location.hash);
    }

    #requestFormSubmit() {
      this.recordPaneEl.dispatchEvent(
        new CustomEvent('infiniteTreeRouter:requestSubmit')
      );
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
     * Sets location hash without running the hashchange navigation path (programmatic sync).
     * @param {string} hash - With or without leading #
     */
    #setHashSilently(hash) {
      const normalized = this.#normalizeHash(hash);

      this._ignoreHashChange = true;
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
     * Checks whether a location hash resolves to a valid tree node ID
     * @param {string} hash - The location hash to validate
     * @returns {boolean}
     * @private
     */
    #isValidTreeHash(hash) {
      const id = InfiniteTreeIds.locationHashToHtmlId(hash);

      return InfiniteTreeIds.parseTreeId(id) !== null;
    }

    /**
     * Returns true for the transient inline-create hash (#new), which is not a
     * tree node but must not be reverted.
     * @param {string} hash - The location hash to check
     * @returns {boolean}
     * @private
     */
    #isInlineCreateHash(hash) {
      return hash === '#new' || hash === 'new';
    }

    /**
     * Completes the save transaction by closing modal, navigating to target,
     * and clearing transaction state
     */
    #completeTransaction() {
      if (!this._pendingTransaction) return;

      const { target } = this._pendingTransaction;

      $('#saveYourChangesModal').modal('hide');

      if (target) {
        this.setHash(target);
      }

      this._pendingTransaction = null;
    }
  }

  exports.InfiniteTreeRouter = InfiniteTreeRouter;
})(window);
