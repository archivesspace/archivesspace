//= require InfiniteTreeIds

(function (exports) {
  class InfiniteTreeRecordPane {
    /**
     * @constructor
     * @param {string} uriFragment - The document's URI fragment at page load
     * @param {string} rootRecordUri - The backend URI of the root record
     * @returns {InfiniteTreeRecordPane}
     */
    constructor(uriFragment, rootRecordUri) {
      this.container = document.querySelector('#infinite-tree-record-pane');

      this.container.addEventListener('infiniteTree:nodeSelect', e => {
        this.loadRecord(e.detail.recordPath);
      });

      const shouldLoadRoot =
        uriFragment === '' ||
        uriFragment === InfiniteTreeIds.treeLinkUrl(rootRecordUri);

      if (shouldLoadRoot) {
        this.loadRecord(InfiniteTreeIds.backendUriToFrontendUri(rootRecordUri));
      } else {
        this.loadRecord(InfiniteTreeIds.locationHashToFrontendUri(uriFragment));
      }
    }

    /**
     * @param {string} recordPath - The path to the record, e.g. "resources/123"
     */
    async loadRecord(recordPath) {
      const url = AS.app_prefix(recordPath) + '?inline=true';

      this.#blockUI();

      try {
        const html = await this.#fetchRecordHtml(url);

        this.container.innerHTML = html;

        this.#initializeRecordForm();
      } catch (error) {
        this.container.appendChild(this.#errorMessageFragment(error));
      } finally {
        this.#unblockUI();
      }
    }

    #blockUI() {
      this.container.classList.add('blocked');
    }

    #unblockUI() {
      this.container.classList.remove('blocked');
    }

    /**
     * Loads content from the given URL and returns the HTML
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
