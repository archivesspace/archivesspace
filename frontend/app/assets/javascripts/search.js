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

      setTimeout(function() {
        if ($(".multiselect-column :input:checked", $table).length > 0) {
          $table.trigger("multiselectselected.aspace");
        } else {
          $table.trigger("multiselectempty.aspace");
        }
      });
    });

    $(".multiselect-enabled").each(function() {
      var $multiselectEffectedWidget = $(this);
      if ($table.is($multiselectEffectedWidget.data("multiselect"))) {
        $table.on("multiselectselected.aspace", function() {
          $multiselectEffectedWidget.removeAttr("disabled");
          var selected_records = $.makeArray($(".multiselect-column :input:checked", $table).map(function() {return $(this).val();}));
          $multiselectEffectedWidget.data("form-data", {
            record_uris: selected_records
          });
        }).on("multiselectempty.aspace", function() {
          $multiselectEffectedWidget.attr("disabled", "disabled");
            $multiselectEffectedWidget.data("form-data", {});
        });
      }
    });

    $(".multiselect-column :input:checked", $table).closest("tr").addClass("selected");

  };

  $(".table-search-results[data-multiselect]").each(init_multiselect_listing);
});