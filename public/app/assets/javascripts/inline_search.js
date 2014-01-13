$(function() {

  var initSearchNav = function($section) {
    var $resultsContainer = $section.children('.inline-results');

    var performSearch = function(url) {
      $resultsContainer.load(url);
    }

    performSearch($section.data("url"));

    $resultsContainer.on("click", ".pagination a, .sort-by-action .dropdown-menu a", function(event) {
      event.preventDefault();
      event.stopPropagation();

      performSearch($(this).attr("href"));
    });
  };
    

  $('.search-data-as-subrecord').each(function() {
    initSearchNav($(this));
  });
});
