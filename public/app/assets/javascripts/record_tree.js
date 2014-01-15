(function () {
    "use strict";

    var RecordTree = function () {
    };

  RecordTree.prototype.search_initialised = false;

    RecordTree.prototype.add_children = function (uri, container) {
        var self = this;
        $.ajax({
            url: APP_PATH + "tree",
            data: {
                uri: uri
            },
            dataType: "json",
            type: "GET",
            beforeSend: function() {
              container.append(AS.renderTemplate("template_record_tree_loading"));
            },
            success: function (json) {
              container.empty();

              if (json == null || json.direct_children.length == 0) {
                container.replaceWith(AS.renderTemplate("template_record_tree_empty"));
                return;
              }

              if (!self.search_initialised) {
                self.init_search(container);
              }

              $(json.direct_children).each(function (idx, child) {
                var $node = AS.renderTemplate("template_record_tree_node", child);
                var elt = $("<li>").text(child.title);
                container.append($node);
              });
            }
        });
    };

    RecordTree.prototype.init_search = function(container) {
      var $section = container.closest("#components");

      if (!$section.data('show-search')) {
        return;
      }

      this.search_initialised = true;

      var $componentsTab = $("#componentsTab", $section);
      var $searchResultsContainer = $("#components_search_results", $section);

      $componentsTab.removeClass("hide");

      // Init the components tab
      $('a', $componentsTab).click(function (e) {
        e.preventDefault();
        $(this).tab('show');
      });

      // Init the search action
      $("form", $section).ajaxForm({
        type: "GET",
        success: function(responseText, status, xhr) {
          $searchResultsContainer.html(responseText);
        }
      });

      $searchResultsContainer.on("click", ".pagination a, .sort-by-action .dropdown-menu a", function(event) {
        event.preventDefault();
        event.stopPropagation();

        $searchResultsContainer.load($(this).attr("href"));
      });
    }

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
                if ($sublist.is(":visible")) {
                  $node.addClass("expanded").removeClass("expanded");
                } else {
                  $node.removeClass("expanded").addClass("expanded");
                }
                $sublist.toggle();
              } else {
                tree.add_children($node.data("uri"), $sublist);
                $node.addClass("loaded").addClass("expanded");
              }
            });
        });
    });

}());
