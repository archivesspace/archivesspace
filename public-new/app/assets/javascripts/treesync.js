//= require jquery.ba-hashchange

(function(exports) {

    function TreeSync(repo_id) {
        this.repo_id = repo_id;
    };

    TreeSync.prototype.treeIsReady = function(tree) {
        this.tree = tree;

        if (this.scroller != undefined) {
            this.ready();
        }
    };

    TreeSync.prototype.infiniteScrollIsReady = function(scroller) {
        this.scroller = scroller;

        if (this.tree != undefined) {
            this.ready();
        }
    };

    TreeSync.prototype.ready = function() {
        var self = this;

        self.setupHashChange();
        self.scroller.registerScrollCallback($.proxy(self.handleScroll, this));

        // Sync the tree
        var tree_id = self.tree_id_from_hash();
        if (tree_id != null) {
            self.tree.setCurrentNode(tree_id, function () {
                self.tree.elt.scrollTo('#' + tree_id, 0, {offset: -50});
            });
        }
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

        var uri = self.uriForTreeId(tree_id);

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

    TreeSync.prototype.SCROLL_TIMEOUT = 500;
    TreeSync.prototype.handleScroll = function() {
        var self = this;

        var syncAfterScroll = function () {
            var $record = self.scroller.getClosestElement();
            var uri = $record.data('uri');
            var tree_id = TreeIds.uri_to_tree_id(uri);
            self.tree.setCurrentNode(tree_id, function() {
                self.tree.elt.scrollTo('#'+tree_id, 0, {offset: -50});
            });
        };

        clearTimeout(this.scrollTimeout);

        this.scrollTimeout = setTimeout(function() {
            syncAfterScroll();
        }, this.SCROLL_TIMEOUT);
    };


    TreeSync.prototype.uriForTreeId = function(tree_id) {
        var parsed_tree_id = TreeIds.parse_tree_id(tree_id);
        return '/repositories/'+this.repo_id+'/'+parsed_tree_id.type + 's/'+parsed_tree_id.id;
    };

    exports.TreeSync = TreeSync;

}(window));
