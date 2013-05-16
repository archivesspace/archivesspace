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

        var $currentRow = $(event.target).closest("tr");
        if ($currentRow.length === 0) {
          $currentRow = $("table tbody tr:first", $this);
        }

        index = index+1;

        var $row = $(AS.renderTemplate("template_rde_row", {
          path: "archival_record_children[children]["+index+"]",
          id_path: "archival_record_children_children__"+index+"_",
          index: index
        }));

        // Apply any sticky columns
        if ($currentRow.length > 0) {
          $("th", $this).each(function(i, th) {
            var $th = $(th);
            if ($th.hasClass("sticky")) {
              // populate the input from the current or top row
              var $source = $("td:nth-child("+(i+1)+") :input", $currentRow);
              var $target = $("td:nth-child("+(i+1)+") :input", $row);

              if ($source.is(":checkbox")) {
                if ($source.attr("checked")) {
                  $target.attr("checked", "checked");
                } else {
                  $target.removeAttr("checked");
                }
              } else {
                $target.val($source.val());
              }
            }
          });
        }

        $("table tbody", $this).append($row);
        $(":input:visible:first", $row).focus();
      });

      $modal.on("keydown", function(event) {
        if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      });

      $modal.on("keydown", ":input, input[type='text']", function(event) {
        var $row = $(event.target).closest("tr");
        var $cell = $(event.target).closest("td");

        if (event.keyCode === 13) { // return
          event.preventDefault();

          if (event.shiftKey) {
            if ($row.index() === $row.siblings().length) {
              // create a new row if return on the last row
              $(".add-row", $row).trigger("click");
            } else {
              // focus the next row from the beginning
              $(":input:visible:first", $row.next()).focus();
            }
          }
        } else if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
          return true;
        } else if (event.keyCode === 37) { // left
          if (event.shiftKey) {
            event.preventDefault();
            $(":input:visible:first", $cell.prev()).focus();
          }
        } else if (event.keyCode === 40) { // down
          if (event.shiftKey) {
            event.preventDefault();
            if ($row.index() < $row.siblings().length) {
              $(":input:visible:first", $("td", $row.next())[$cell.index()]).focus();
            }
          }
        } else if (event.keyCode === 38) { // up
          if (event.shiftKey) {
            event.preventDefault();
            if ($row.index() > 0) {
              $(":input:visible:first", $("td", $row.prev())[$cell.index()]).focus();
            }
          }
        } else if (event.keyCode === 39) { // right
          if (event.shiftKey) {
            event.preventDefault();
            $(":input:visible:first", $cell.next()).focus();
          }
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

            if ($this.length) {
              $("tbody tr", $this).each(function() {
                var $row = $(this);
                if ($("td.error", $row).length > 0) {
                  $row.addClass("invalid");
                } else {
                  $row.addClass("valid");
                }
              });

              initAjaxForm();
            } else {
              // we're good to go!
              setTimeout(function() {
                location.reload(true);
              }, 1000);
            }
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