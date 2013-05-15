$(function() {

  $.fn.init_rapid_data_entry_form = function($modal) {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var index = 0;

      //$(document).triggerHandler("subrecordcreated.aspace", ["rde", $this]);
      //$(document).triggerHandler("subrecordmonkeypatch.aspace", [$this]);
      $modal.on("click", ".remove-row", function(event) {
        event.preventDefault();
        event.stopPropagation();
        $(event.target).closest("tr").remove();
      });

      $modal.on("click", ".add-row", function(event) {
        event.preventDefault();
        event.stopPropagation();

        index = index+1;
        var $row = $(AS.renderTemplate("template_rde_row", {
          path: "archival_object_children[children]["+index+"]",
          id_path: "archival_object_children_children__"+index+"_",
          index: index
        }));
        $("table tbody", $this).append($row);
        $(":input:first:visible", $row).focus();
      });

      $modal.on("keydown", function(event) {
        if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      });

      $modal.on("keydown", "input[type='text']", function(event) {
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

      var initAjaxForm = function() {
        $this.ajaxForm({
          target: $(".rde-wrapper", $modal),
          success: function() {
            $(window).trigger("resize");
            $this = $("form", "#rapidDataEntryModal");

            $("tbody tr", $this).each(function() {
              var $row = $(this);
              if ($("td.error", $row).length > 0) {
                $row.addClass("invalid");
              } else {
                $row.addClass("valid");
              }
            });

            initAjaxForm();
          }
        });
      };

      // Connect up the $modal form submit button
      $($modal).on("click", ".btn-primary", function() {
        $(this).attr("disabled","disabled");
        $this.submit();
      });

      initAjaxForm();

      $(window).trigger("resize");
    });
  };


  $(document).bind("rdeshow.aspace", function(event, node, button) {
    var $modal = AS.openCustomModal("rapidDataEntryModal", "RDE", AS.renderTemplate("modal_content_loading_template"), 'full', {keyboard: false});

    $.ajax({
      url: "/"+node.attr("rel")+"s/"+node.data("id")+"/rde",
      success: function(data) {
        $(".modal-body", $modal).replaceWith(data);
        $("form", "#rapidDataEntryModal").init_rapid_data_entry_form($modal);
      }
    });

  });

});