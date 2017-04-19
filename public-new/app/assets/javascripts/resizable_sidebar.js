function ResizableSidebar($sidebar) {
    this.$sidebar = $sidebar;

    this.$row = $sidebar.closest('.row');
    this.$content_pane = this.$row.find('> .col-sm-9');

    if (this.$content_pane.length == 0) {
        // only do things if there's a content pane and a sidebar
        this.$sidebar.removeClass('resizable-sidebar');
        return;
    };

    this.$row.addClass('has-resizable-content');

    this.add_handle();
    this.bind_events();
};

ResizableSidebar.prototype.add_handle = function() {
    var $handle = $('<a>').attr('href', 'javascript:void(0);');
    $handle.attr('aria-hidden', 'true');
    $handle.addClass('resizable-sidebar-handle');

    this.$sidebar.append($handle);

    this.$handle = $handle;
};

ResizableSidebar.prototype.bind_events = function() {
    var self = this;

    self.$handle.on('mousedown', function (e) {
        self.isResizing = true;
        self.lastDownX = e.clientX;
    });

    $(document).on('mousemove', function (e) {
        if (!self.isResizing) {
            return;
        }

        var cursor_x = e.clientX;
        var right_offset = (self.$row.width() + self.$row.offset().left) - cursor_x;

        right_offset = Math.max(right_offset, 200);
        var new_content_width = Math.max(self.$row.width() - right_offset, 300);

        self.$sidebar.css('width', 0);
        self.$content_pane.css('width', new_content_width);
        self.$sidebar.css('width', self.$row.width() - new_content_width);

        // position the infinite scrollbar too, if it's about
        if ($('.infinite-record-scrollbar').length > 0) {
            $('.infinite-record-scrollbar').css('left', self.$row.offset().left + new_content_width - 20);
        }
    }).on('mouseup', function (e) {
        self.isResizing = false;
    });
};

$(function() {
    $('.resizable-sidebar').each(function() {
        new ResizableSidebar($(this));
    });
});