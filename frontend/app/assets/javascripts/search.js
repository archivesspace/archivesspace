$(function() {

  var init_multiselect_listing = function() {
    var $table = $(this);


    $table.on("click", "tbody td:not(.table-record-actions)", function(event) {
      event.stopPropagation();
      event.preventDefault();

      var $row = $(this).closest("tr");
      $(".multiselect-column :input", $row).trigger("click");
    }).on("click", ".multiselect-column :input", function(event) {
      event.stopPropagation();

      var $this = $(this);
      var $row = $this.closest("tr");
      $row.toggleClass("selected");
    });

  };

  $(".table-search-results[data-multiselect]").each(init_multiselect_listing);
});