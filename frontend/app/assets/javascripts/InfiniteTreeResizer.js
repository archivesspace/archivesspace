(function (exports) {
  class InfiniteTreeResizer {
    static #MIN_HEIGHT = 60;
    static #MAXIMIZED_MARGIN_BOTTOM = 50;

    /**
     * @param {HTMLElement} container - The tree container to be resized
     */
    constructor(container) {
      this.container = container;
      this.isResizing = false;
      this.startY = 0;
      this.startHeight = 0;
      this.minHeight = InfiniteTreeResizer.#MIN_HEIGHT;
      this.maximizedMarginBottom = InfiniteTreeResizer.#MAXIMIZED_MARGIN_BOTTOM;
      this.handle = document.querySelector('[data-resize-handle]');
      this.toggleBtn = document.querySelector('[data-resize-toggle]');

      this.handle.addEventListener('mousedown', this.onMouseDown.bind(this));
      this.handle.addEventListener('keydown', this.onHandleKeyDown.bind(this));
      this.handle.addEventListener('touchstart', this.onTouchStart.bind(this), {
        passive: false,
      });
      this.toggleBtn.addEventListener('click', this.toggleMaximized.bind(this));
      window.addEventListener('resize', () => {
        this.updateHandleAriaAttrs();
      });

      this.updateHandleAriaAttrs();
    }

    onMouseDown(e) {
      this.isResizing = true;
      this.startY = e.clientY;
      this.startHeight = this.container.offsetHeight;
      document.body.style.userSelect = 'none';

      this.onMouseMoveHandler = this.onMouseMove.bind(this); // needed for removing the listener
      this.onMouseUpHandler = this.onMouseUp.bind(this); // needed for removing the listener

      document.addEventListener('mousemove', this.onMouseMoveHandler);
      document.addEventListener('mouseup', this.onMouseUpHandler);
    }

    onMouseMove(e) {
      if (!this.isResizing) return;
      const deltaY = e.clientY - this.startY;
      const newHeight = Math.max(this.minHeight, this.startHeight + deltaY);
      this.container.style.height = `${newHeight}px`;
      this.updateHandleAriaAttrs(newHeight);
    }

    onMouseUp() {
      this.isResizing = false;
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', this.onMouseMoveHandler);
      document.removeEventListener('mouseup', this.onMouseUpHandler);
    }

    onTouchStart(e) {
      if (e.touches.length !== 1) return; // ignore multi-touch

      this.isResizing = true;
      this.startY = e.touches[0].clientY;
      this.startHeight = this.container.offsetHeight;
      document.body.style.userSelect = 'none';

      this.onTouchMoveHandler = this.onTouchMove.bind(this);
      this.onTouchEndHandler = this.onTouchEnd.bind(this);

      document.addEventListener('touchmove', this.onTouchMoveHandler, {
        passive: false,
      });
      document.addEventListener('touchend', this.onTouchEndHandler);
    }

    onTouchMove(e) {
      if (!this.isResizing) return;

      const deltaY = e.touches[0].clientY - this.startY;
      const newHeight = Math.max(this.minHeight, this.startHeight + deltaY);

      this.container.style.height = `${newHeight}px`;
      this.updateHandleAriaAttrs(newHeight);

      e.preventDefault(); // Prevent scrolling while resizing
    }

    onTouchEnd() {
      this.isResizing = false;
      document.body.style.userSelect = '';
      document.removeEventListener('touchmove', this.onTouchMoveHandler);
      document.removeEventListener('touchend', this.onTouchEndHandler);
    }

    onHandleKeyDown(e) {
      const step = 10;
      const largeStep = 50;
      let newHeight = this.container.offsetHeight;

      switch (e.key) {
        case 'ArrowUp':
        case 'ArrowRight':
          newHeight = Math.min(this.availableHeight, newHeight + step);
          break;

        case 'ArrowDown':
        case 'ArrowLeft':
          newHeight = Math.max(this.minHeight, newHeight - step);
          break;

        case 'PageUp':
          newHeight = Math.min(this.availableHeight, newHeight + largeStep);
          break;

        case 'PageDown':
          newHeight = Math.max(this.minHeight, newHeight - largeStep);
          break;

        case 'Home':
          newHeight = this.minHeight;
          break;

        case 'End':
          newHeight = this.availableHeight;
          break;

        default:
          return;
      }

      this.container.style.height = `${newHeight}px`;
      this.updateHandleAriaAttrs(newHeight);

      e.preventDefault();
    }

    toggleMaximized() {
      if (this.isResizing) return;

      this.isResizing = true;

      if (!this.isMaximized) {
        this.container.style.height = `${this.availableHeight}px`;
        this.handle.classList.add('maximized');
        this.toggleBtn.setAttribute('aria-expanded', true);
      } else {
        this.container.style.height = `${this.minHeight}px`;
        this.handle.classList.remove('maximized');
        this.toggleBtn.setAttribute('aria-expanded', false);
      }

      this.isResizing = false;
    }

    /**
     * @param {number} [nowHeight] Current height in pixels
     */
    updateHandleAriaAttrs(nowHeight = this.container.offsetHeight) {
      this.handle.setAttribute('aria-valuenow', nowHeight);
      this.handle.setAttribute('aria-valuemax', this.availableHeight);
    }

    get availableHeight() {
      return (
        window.innerHeight -
        this.maximizedMarginBottom -
        this.container.getBoundingClientRect().top
      );
    }

    get isMaximized() {
      return this.handle.classList.contains('maximized');
    }
  }

  exports.InfiniteTreeResizer = InfiniteTreeResizer;
})(window);
