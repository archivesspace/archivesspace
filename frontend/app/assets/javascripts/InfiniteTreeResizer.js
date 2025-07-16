(function (exports) {
  class InfiniteTreeResizer {
    /**
     * @param {HTMLElement} container - The tree container to be resized
     */
    constructor(container) {
      this.container = container;
      this.isResizing = false;
      this.startY = 0;
      this.startHeight = 0;
      this.minHeight = 60;
      this.maximizedMarginBottom = 50;
      this.handle = document.querySelector('[data-resize-handle]');
      this.toggleBtn = document.querySelector('[data-resize-toggle]');

      this.handle.addEventListener('mousedown', this.onMouseDown.bind(this));
      this.toggleBtn.addEventListener('click', this.toggleHeight.bind(this));
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
    }

    onMouseUp() {
      this.isResizing = false;
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', this.onMouseMoveHandler);
      document.removeEventListener('mouseup', this.onMouseUpHandler);
    }

    toggleHeight() {
      if (this.isResizing) return;

      this.isResizing = true;

      if (!this.isMaximized) {
        this.handle.classList.add('maximized');

        this.container.style.height = `${
          window.innerHeight -
          this.maximizedMarginBottom -
          this.container.getBoundingClientRect().top
        }px`;
      } else {
        this.handle.classList.remove('maximized');
        this.container.style.height = `${this.minHeight}px`;
      }

      this.isResizing = false;
    }

    get isMaximized() {
      return this.handle.classList.contains('maximized');
    }
  }

  exports.InfiniteTreeResizer = InfiniteTreeResizer;
})(window);
