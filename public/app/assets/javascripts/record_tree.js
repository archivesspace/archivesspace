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
                var list = $("<ul />");
                $(json.direct_children).each(function (idx, child) {
                    var elt = $("<li>").text(child.title);

                    if (child.has_children) {
                        var sublist = $("<ul />");
                        elt.append(sublist)

                        elt.on('click', function (e) {
                            self.add_children(child.record_uri, sublist);
                        });
                    }

                    list.append(elt);
                });

                container.append(list)
            }
        });
    };


    $(document).ready(function () {
        $(".record-tree").each(function (idx, elt) {
            var elt = $(elt);
            var tree = new RecordTree();
            tree.add_children(elt.data("root-uri"), elt);
        });
    });

}());
