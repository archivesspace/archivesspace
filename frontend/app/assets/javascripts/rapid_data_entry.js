$(function() {

  $.fn.init_rapid_data_entry_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var index = 0;

      //$(document).triggerHandler("subrecordcreated.aspace", ["rde", $this]);
      //$(document).triggerHandler("subrecordmonkeypatch.aspace", [$this]);
      $this.on("click", ".remove-row", function(event) {
        event.preventDefault();
        event.stopPropagation();
        $(event.target).closest("tr").remove();
      });

      $this.on("click", ".add-row", function(event) {
        event.preventDefault();
        event.stopPropagation();

        index = index+1;
        var $row = $(AS.renderTemplate("template_rde_row", {
          path: "foo",
          id_path: "foo",
          index: index
        }));
        $("table tbody", $this).append($row);
        $(":input:first:visible", $row).focus();
      });

      $this.on("keydown", function(event) {
        if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      });

      $this.on("keydown", "input[type='text']", function(event) {
        var $row = $(event.target).closest("tr");

        if (event.keyCode === 13) { // return
          event.preventDefault();
          if ($row.index() === $row.siblings().length) {
            // create a new row if return on the last row
            $(".add-row", $row).trigger("click");
          } else {
            // focus the next row from the beginning
            $(":input:first:visible", $row.next()).focus();
          }
        } else if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
          return true;
        } else if (event.keyCode === 37) { // left
          event.preventDefault();
        } else if (event.keyCode === 38) { // up
          event.preventDefault();
        } else if (event.keyCode === 39) { // right
          event.preventDefault();
        } else if (event.keyCode === 40) { // down
          event.preventDefault();
        } else {
          // we're cool.
        }
      });

    });
  };


  $(document).bind("rdeinit.aspace", function(event, rdeform) {
    rdeform.init_rapid_data_entry_form();
  });

  $(document).bind("rdeshow.aspace", function(event, node, button) {
    var modal_contents = AS.renderTemplate("template_rde", {
      path: node.attr("rel"),
      id_path: node.attr("rel"),
      index: "${index}"
    });

    AS.openCustomModal("rapidDataEntryModal", "RDE", modal_contents, true, {keyboard: false});

    $("form", "#rapidDataEntryModal").init_rapid_data_entry_form();
  });

});