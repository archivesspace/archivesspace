function ResizableSidebar($sidebar) {
  this.$sidebar = $sidebar;
  this.position = this.$sidebar.attr('data-sidebar-position') || 'right';

  this.$row = $sidebar.closest('.row');
  this.$content_pane = this.$row.find('> .resizable-content-pane');

  if (this.$content_pane.length == 0) {
    // only do things if there's a content pane and a sidebar
    this.$sidebar.removeClass('resizable-sidebar');
    return;
  }

  this.$row.addClass('has-resizable-content');

  this.add_handle();
  this.bind_events();
}

ResizableSidebar.prototype.add_handle = function () {
  var $handle = $('<input>').attr('type', 'range');
  $handle.attr('value', 75);
  $handle.attr('max', 88);
  $handle.attr('min', 24);
  $handle.attr('aria-label', 'resizable sidebar handle');
  $handle.attr('id', 'accessible_slider');
  $handle.addClass('resizable-sidebar-handle');

  this.$sidebar.append($handle);

  this.$handle = $handle;
};

ResizableSidebar.prototype.bind_events = function () {
  var self = this;

  self.$handle.on('mousedown keydown', function () {
    self.isResizing = true;
  });

  $(document)
    .on('mousemove', function (e) {
      if (!self.isResizing) {
        return;
      }

      self.resize_by_mouse(e.clientX);
    })
    .on('mouseup', function () {
      self.isResizing = false;
    });

  // ANW-1323: Make resizable input slider work with keyboard commands alone
  $(document)
    .on('keydown', function (e) {
      const keys = ['ArrowRight', 'ArrowLeft', 'ArrowUp', 'ArrowDown'];

      if (!self.isResizing || !keys.includes(e.key)) {
        return;
      }

      e.preventDefault();

      self.resize_by_key(e.key);
    })
    .on('keyup', function () {
      self.isResizing = false;
    });
};

/**
 * @param {Number} clientX - the horizontal coordinate of the mousemove event
 * @description Resize sidebar and content based on clientX and sidebar position
 */
ResizableSidebar.prototype.resize_by_mouse = function (clientX) {
  const sidebar_width =
    this.position === 'left'
      ? Math.max(clientX - this.$row.offset().left, 200)
      : Math.max(this.$row.width() + this.$row.offset().left - clientX, 200);
  const content_width = Math.max(this.$row.width() - sidebar_width, 300);

  this.$sidebar.css('width', sidebar_width);
  this.$sidebar.css('max-width', sidebar_width);
  this.$sidebar.css('flex-basis', sidebar_width);
  this.$content_pane.css('width', content_width);
  this.$content_pane.css('max-width', content_width);
  this.$content_pane.css('flex-basis', content_width);
};

/**
 * @param {string} key - the Arrow key pressed
 * @description Resize sidebar and content based on Arrow keys and sidebar position
 */
ResizableSidebar.prototype.resize_by_key = function (key) {
  const isIncrease = () => {
    return (
      key === 'ArrowUp' ||
      (this.position === 'left' && key === 'ArrowRight') ||
      (this.position === 'right' && key === 'ArrowLeft')
    );
  };

  let adjustment = isIncrease() ? 10 : -10;

  const sidebar_width = Math.max(
    parseInt(this.$sidebar.css('width')) + adjustment,
    200
  );
  const content_width = Math.max(this.$row.width() - sidebar_width, 300);

  this.$sidebar.css('width', sidebar_width);
  this.$sidebar.css('max-width', sidebar_width);
  this.$sidebar.css('flex-basis', sidebar_width);
  this.$content_pane.css('width', content_width);
  this.$content_pane.css('max-width', content_width);
  this.$content_pane.css('flex-basis', content_width);
};

$(function () {
  $('.resizable-sidebar').each(function () {
    $(document).off('keydown.bs.dropdown.data-api');
    new ResizableSidebar($(this));
  });
});
