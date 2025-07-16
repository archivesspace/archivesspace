(function (exports) {
  class InfiniteTreeResizer {
    /**
     * @param {HTMLElement} container - The tree container to be resized
     */
    constructor(container) {
      this.container = container;
      this.handle = document.querySelector('[data-resize-handle]');
      this.toggle = document.querySelector('[data-resize-toggle]');
      this.isResizing = false;
      this.startY = 0;
      this.startHeight = 0;
      this.minHeight = 60;

      this.handle.addEventListener('mousedown', this.onMouseDown.bind(this));
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

    onMouseUp(e) {
      this.isResizing = false;
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', this.onMouseMoveHandler);
      document.removeEventListener('mouseup', this.onMouseUpHandler);
    }
  }

  exports.InfiniteTreeResizer = InfiniteTreeResizer;
})(window);
