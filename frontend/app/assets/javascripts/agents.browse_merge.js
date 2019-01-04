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
      var target = "";
      if ($table.is($multiselectEffectedWidget.data("multiselect"))) {
        $table.on("multiselectselected.aspace", function() {
          $multiselectEffectedWidget.removeAttr("disabled");
          if ($(".multiselect-column :input:checked", $table).length == 1) {
            target = $(".multiselect-column :input:checked", $table).val();
          }
          console.log("Target " + target);
          var sel = $(".multiselect-column :input:checked", $table).map(function() {
            if ($(this).val() != target) {
              return $(this).val();
            }
          });
          var selected_records = $.makeArray(sel);
          console.log("Selected Records " + selected_records);
          selected_records.unshift(target);
          console.log("Target first selected_records " + selected_records);
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
