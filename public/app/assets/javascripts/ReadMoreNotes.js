(function (exports) {
  class ReadMoreNotes {
    /**
     * @constructor
     * @description - Listen and respond to "read more" events related to long top-level
     * notes in a Resource Collection Overview
     * @param {HTMLButtonElement} button - The button for expanding and collapsing
     * the long note
     * @returns {ReadMoreNotes} - A ReadMore object
     */
    constructor(button) {
      this.button = button;
      this.listen();
    }

    /**
     * @description - Toggle the expanded state of the long note
     */
    listen() {
      this.button.addEventListener('click', () => {
        const expanded = this.button.getAttribute('aria-expanded') === 'true';
        this.button.setAttribute('aria-expanded', String(!expanded));
      });
    }
  }

  exports.ReadMoreNotes = ReadMoreNotes;
})(window);
