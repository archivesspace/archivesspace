(function () {
    "use strict";

    var RecordTree = function () {
    };

    RecordTree.prototype.add_children = function (uri, container) {
        var self = this;
        $.ajax({
            url: "/tree",
            data: {
                uri: uri
            },
            dataType: "json",
            type: "GET",
            success: function (json) {
                $(json.direct_children).each(function (idx, child) {
                  var $node = AS.renderTemplate("template_record_tree_node", child);
                    var elt = $("<li>").text(child.title);
                    container.append($node);
                });
            }
        });
    };

    $(document).ready(function () {
        $(".record-tree").each(function (idx, elt) {
            var elt = $(elt);
            var tree = new RecordTree();
            tree.add_children(elt.data("root-uri"), elt);

            elt.on("click", ".record-tree-node-toggle", function(event) {
              event.stopPropagation();
              event.preventDefault();

              var $node = $(this).closest("li");
              var $sublist = $node.find(".record-sub-tree:first");
              if ($node.hasClass("loaded")) {
                $sublist.toggle();
              } else {
                tree.add_children($node.data("uri"), $sublist);
                $node.addClass("loaded");
              }
            });
        });
    });

}());
