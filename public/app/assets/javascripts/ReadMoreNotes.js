(function (exports) {
  class ReadMoreNotes {
    /**
     * @constructor
     * @description - Listen and respond to "read more" events related to long top-level
     * notes in a Resource Collection Overview
     * @param {HTMLElement} readmoreElement - The parent element containing
     * the long note and controls for expanding and collapsing it
     * @returns {ReadMoreNotes} - A ReadMore object
     */
    constructor(readmoreElement) {
      this.readmore = readmoreElement;
      this.state = this.readmore.querySelector('.readmore__state');
      this.label = this.readmore.querySelector('.readmore__label');

      this.listen();
    }

    /**
     * @description - Add event listeners for accessibility
     */
    listen() {
      this.state.addEventListener('change', () => {
        this.setLabelAriaExpanded(this.state.checked);
      });

      this.label.addEventListener('keydown', e => {
        if (!this.state.checked && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          this.state.checked = true;
          this.setLabelAriaExpanded(this.state.checked);
        } else if (this.state.checked && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          this.state.checked = false;
          this.setLabelAriaExpanded(this.state.checked);
        }
      });
    }

    /**
     * @description - Set the aria-expanded attribute on the toggle/label element
     * @param {boolean} value - The value to set the aria-expanded attribute to
     * @todo - Make this a private method once our js asset pipeline supports es6
     */
    setLabelAriaExpanded(value) {
      this.label.setAttribute('aria-expanded', value);
    }
  }

  exports.ReadMoreNotes = ReadMoreNotes;
})(window);
