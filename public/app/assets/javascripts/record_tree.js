(function () {
    "use strict";

    var init_search = function(container) {
      if (!container.data('show-search')) {
        return;
      }

      var $componentsTab = $("#componentsTab", container);
      var $searchResultsContainer = $("#components_search_results", container);

      $componentsTab.removeClass("hide");

      // Init the components tab
      $('a', $componentsTab).click(function (e) {
        e.preventDefault();
        $(this).tab('show');
      });

      // Init the search action
      $("form", container).ajaxForm({
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
        init_search($('#components'));
    });

}());
