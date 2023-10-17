(function (exports) {
  class ModalManager {
    /**
     * @constructor
     * @param {Element} modal - The modal DOM element
     */
    constructor(modal) {
      this.modal = modal;
    }

    get isOpen() {
      return this.modal.open;
    }

    toggle() {
      if (this.modal.open) {
        this.modal.close();
      } else {
        this.modal.showModal();
      }
    }
  }

  exports.ModalManager = ModalManager;
})(window);
