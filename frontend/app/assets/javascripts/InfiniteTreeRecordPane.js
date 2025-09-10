(function (exports) {
  class InfiniteTreeRecordPane {
    constructor() {
      this.container = document.querySelector('#infinite-tree-record-pane');

      this.container.addEventListener('infiniteTree:nodeSelect', e => {
        this.loadRecord(e.detail.requestPath);
      });
    }

    /**
     * @param {string} requestPath - The app-prefixed frontend URI to the record, e.g. "/resources/123"
     */
    async loadRecord(requestPath) {
      const url = requestPath + '?inline=true';

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
