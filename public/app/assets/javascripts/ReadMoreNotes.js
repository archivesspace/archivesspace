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
      this.more = this.readmore.querySelector('.readmore__more-label');
      this.less = this.readmore.querySelector('.readmore__less-label');

      this.listen();
    }

    /**
     * @description - Add event listeners for accessibility
     */
    listen() {
      this.state.addEventListener('change', () => {
        this.setAriaExpanded(this.state.checked);
      });

      this.readmore.addEventListener('keydown', e => {
        if (e.target === this.more && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          const x = window.scrollX;
          const y = window.scrollY;

          this.state.checked = true;
          this.setAriaExpanded(this.state.checked);

          this.less.focus();

          window.scrollTo(x, y); // Don't scroll down to this.less
        } else if (
          e.target === this.less &&
          (e.key === 'Enter' || e.key === ' ')
        ) {
          e.preventDefault();
          this.state.checked = false;
          this.setAriaExpanded(this.state.checked);

          this.more.focus();
        }
      });
    }

    /**
     * @description - Set the aria-expanded attribute on the state element
     * @param {boolean} value - The value to set the aria-expanded attribute to
     * @todo - Make this a private method once our js asset pipeline supports es6
     */
    setAriaExpanded(value) {
      this.state.setAttribute('aria-expanded', value);
    }
  }

  exports.ReadMoreNotes = ReadMoreNotes;
})(window);
