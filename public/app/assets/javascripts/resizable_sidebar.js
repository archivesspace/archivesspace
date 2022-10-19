function ResizableSidebar($sidebar) {
  this.$sidebar = $sidebar;

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

  self.$handle.on('mousedown keydown', function (e) {
    self.isResizing = true;
  });

  $(document)
    .on('mousemove', function (e) {
      if (!self.isResizing) {
        return;
      }

      var cursor_x = e.clientX;
      var right_offset = self.$row.width() + self.$row.offset().left - cursor_x;

      right_offset = Math.max(right_offset, 200);
      var new_content_width = Math.max(self.$row.width() - right_offset, 300);

      self.$sidebar.css('width', 0);
      self.$content_pane.css('width', new_content_width);
      self.$sidebar.css('width', self.$row.width() - new_content_width - 20);

      // position the infinite scrollbar too, if it's about
      if ($('.infinite-record-scrollbar').length > 0) {
        $('.infinite-record-scrollbar').css(
          'left',
          self.$row.offset().left + new_content_width - 20
        );
      }
    })
    .on('mouseup', function (e) {
      self.isResizing = false;
    });

  // ANW-1316: Make resizable input slider work with keyboard commands alone
  $(document)
    .on('keydown', function (e) {
      if (!self.isResizing) {
        return;
      }
      var content_width = document.getElementById('content').offsetWidth;
      var slider = document.getElementById('accessible_slider').value;

      var right_offset =
        self.$row.width() +
        self.$row.offset().left -
        content_width * (slider / 100);

      right_offset = Math.max(right_offset, 200);
      var new_content_width = Math.max(self.$row.width() - right_offset, 300);

      self.$sidebar.css('width', 0);
      self.$content_pane.css('width', new_content_width);
      self.$sidebar.css('width', self.$row.width() - new_content_width);

      // position the infinite scrollbar too, if it's about
      if ($('.infinite-record-scrollbar').length > 0) {
        $('.infinite-record-scrollbar').css(
          'left',
          self.$row.offset().left + new_content_width - 20
        );
      }
    })
    .on('keyup', function (e) {
      self.isResizing = false;
    });
};

$(function () {
  $('.resizable-sidebar').each(function () {
    $(document).off('keydown.bs.dropdown.data-api')
    new ResizableSidebar($(this));
  });
});
