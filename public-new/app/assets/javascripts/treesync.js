//= require jquery.ba-hashchange

(function(exports) {

    function TreeSync(tree, scroller) {
        this.tree = tree;
        this.scroller = scroller;

        this.setupHashChange();
    };

    TreeSync.prototype.setupHashChange = function() {
        $(window).hashchange($.proxy(this.handleHashChange, this));

        // if there's a hash, do something upon loading the trees
        this.handleHashChange() 
    };

    TreeSync.prototype.handleHashChange = function() {
        var tree_id = this.tree_id_from_hash();

        if (tree_id == null) {
            return false;
        }

        this.scrollTo(tree_id);
    };

    TreeSync.prototype.tree_id_from_hash = function() {
        if (!location.hash) {
            return;
        }

        var tree_id = location.hash.replace(/^#(tree::)?/, "");

        if (TreeIds.parse_tree_id(tree_id)) {
            return tree_id;
        } else {
            return null;
        }
    };

    TreeSync.prototype.scrollTo = function(tree_id) {
        var self = this;

        var uri = $("#"+tree_id, self.tree.elt).data('uri');
        var $waypoint = self.scroller.wrapper.find('[data-uris*="'+uri+';"], [data-uris$="'+uri+'"]');
        var uris = $waypoint.data('uris').split(';');
        var index = $.inArray(uri, uris);
        var waypoint_number = $waypoint.data('waypointNumber');
        var waypoint_size = $waypoint.data('waypointSize');
        var recordOffset = waypoint_number * waypoint_size + index;

        if ($waypoint.is('.populated')) {
            self.scroller.scrollToRecord(recordOffset);
        } else {
            self.scroller.populateWaypoints($waypoint, false, function() {
                self.scroller.scrollToRecord(recordOffset);
            });
        }
    };

    exports.TreeSync = TreeSync;

}(window));
