var DEFAULT_TREE_PANE_HEIGHT = 100;
var DEFAULT_TREE_MIN_HEIGHT = 60;

function TreeResizer(tree, container) {
    this.tree = tree;
    this.container = container;

    this.setup();
};

TreeResizer.prototype.setup = function() {
    var self = this;

    self.container.resizable({
        handles: "s",
        minHeight: DEFAULT_TREE_MIN_HEIGHT,
        resize: function(event, ui) {
            self.container.removeClass("maximized");
            self.set_height(ui.size.height);
        }
    });

    self.$toggle = $('<a>').addClass('tree-resize-toggle');
    $('.ui-resizable-handle', self.container).append(self.$toggle);

    self.$toggle.on('click', function() {
        self.toggle_height();
    });

    self.reset();
}

TreeResizer.prototype.get_height = function() {
    if (AS.prefixed_cookie("archives-tree-container::height")) {
        return AS.prefixed_cookie("archives-tree-container::height");
    } else {
        return DEFAULT_TREE_PANE_HEIGHT;
    }
};

TreeResizer.prototype.set_height = function(height) {
    AS.prefixed_cookie("archives-tree-container::height", height);
};

TreeResizer.prototype.maximize = function() {
    this.container.addClass("maximized");
    this.container.height($(window).height() - 50);
    document.body.scrollTop  = this.tree.toolbar_renderer.container.offset().top - 5;
};

TreeResizer.prototype.reset = function() {
    this.container.height(this.get_height());
};

TreeResizer.prototype.minimize = function() {
    this.container.removeClass("maximized");
    this.container.height(DEFAULT_TREE_MIN_HEIGHT);
    document.body.scrollTop = this.tree.toolbar_renderer.container.offset().top - 5;
};

TreeResizer.prototype.maximized = function() {
    return this.container.is('.maximized');
}

TreeResizer.prototype.toggle_height = function() {
    var self = this;

    if (self.maximized()) {
        self.minimize();
    } else {
        self.maximize();
    }
};

