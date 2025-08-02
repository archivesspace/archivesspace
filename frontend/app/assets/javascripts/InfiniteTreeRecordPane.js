//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRecordPane {
    /**
     * @constructor
     * @param {string} uriFragment - The document's URI fragment at page load
     * @param {string} rootRecordUri - The URI of the root record
     * @returns {InfiniteTreeRecordPane} - InfiniteTreeRecordPane instance
     */
    constructor(uriFragment, rootRecordUri) {
      this.container = document.querySelector('#infinite-tree-record-pane');

      if (
        uriFragment === '' ||
        uriFragment === InfiniteTreeIds.treeLinkUrl(rootRecordUri)
      ) {
        this.loadRecord(InfiniteTreeIds.backendUriToFrontendUri(rootRecordUri));
      } else {
        this.loadRecord(InfiniteTreeIds.locationHashToFrontendUri(uriFragment));
      }

      this.container.addEventListener('infiniteTree:nodeSelect', e => {
        this.loadRecord(e.detail.recordPath);
      });
    }

    /**
     * Loads the record content for the given record path
     * @param {string} recordPath - The path to the record, e.g. "resources/123"
     */
    loadRecord(recordPath) {
      const url = AS.app_prefix(recordPath);
      const fullUrl = `${url}?inline=true`;

      this.loadPaneContent(fullUrl);
    }

    async loadPaneContent(url, callback = () => {}) {
      this.blockout();

      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: {
            Accept: 'text/html',
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const html = await response.text();

        this.container.innerHTML = html;

        // ⚠️ Use the old jQuery-based event system for compatibility with the many existing form initializations
        $(document).triggerHandler('loadedrecordform.aspace', [
          $(this.container),
        ]);

        callback();
      } catch (error) {
        this.container.appendChild(this.errorMessage(error));
      } finally {
        this.unblockout();
      }
    }

    blockout() {
      this.container.classList.add('blocked');
    }

    unblockout() {
      this.container.classList.remove('blocked');
    }

    /**
     * @param {Error} error - The error object
     * @returns {DocumentFragment} - The error message fragment
     */
    errorMessage(error) {
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
