//= require jquery.event.drag-1.4.min
//= require jquery.kiketable.colsizable-1.1
//= require jquery.columnmanager.min
//= require bootstrap-multiselect

$(function() {

  $.fn.init_rapid_data_entry_form = function($modal, $node) {
    $(this).each(function() {
      var $this = $(this);
      var $table = $("table", $this);

      if ($this.hasClass("initialised")) {
        return;
      }

      // Config from Cookies
      var VISIBLE_COLUMN_INDEXES =  $.cookie("rde.visible") ? JSON.parse($.cookie("rde.visible")) : null;
      var STICKY_COLUMN_INDEXES =  $.cookie("rde.sticky") ? JSON.parse($.cookie("rde.sticky")) : null;
      var COLUMN_WIDTHS =  $.cookie("rde.widths") ? JSON.parse($.cookie("rde.widths")) : null;


      var index = 0;

      $modal.off("click").on("click", ".remove-row", function(event) {
        event.preventDefault();
        event.stopPropagation();

        var $btn = $(event.target).closest("button");

        if ($btn.hasClass("btn-danger")) {
          $btn.closest("tr").remove();
        } else {
          $btn.addClass("btn-danger");
          $("span", $btn).addClass("icon-white");
          setTimeout(function() {
            $btn.removeClass("btn-danger");
            $("span", $btn).removeClass("icon-white");
          }, 10000);
        }
      });

      $modal.on("click", "#rde_reset", function(event) {
        event.preventDefault();
        event.stopPropagation();

        $(":input, .btn", $this).attr("disabled", "disabled");

        // reset cookies
        $.cookie("rde.visible", null);
        $.cookie("rde.widths", null);
        $.cookie("rde.sticky", null);
        VISIBLE_COLUMN_INDEXES = null;
        STICKY_COLUMN_INDEXES = null;
        COLUMN_WIDTHS = null;

        // reload the form
        $(document).triggerHandler("rdeload.aspace", [$node, $modal]);
      });

      $modal.on("click", ".add-row", function(event) {
        event.preventDefault();
        event.stopPropagation();

        var $currentRow = $(event.target).closest("tr");
        if ($currentRow.length === 0) {
          $currentRow = $("table tbody tr:last", $this);
        }

        index = index+1;

        var $row = $(AS.renderTemplate("template_rde_row", {
          path: "archival_record_children[children]["+index+"]",
          id_path: "archival_record_children_children__"+index+"_",
          index: index
        }));

        $(".fieldset-labels th", $this).each(function(i, th) {
          var $th = $(th);

          // Apply any sticky columns
          if ($currentRow.length > 0) {
            if ($th.hasClass("fieldset-label") && $th.hasClass("sticky")) {
              // populate the input from the current or bottom row
              var $source = $(":input:first", $("td", $currentRow).get(i));
              var $target = $(":input:first", $("td", $row).get(i));

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
          }

          // Apply hidden columns
          if ($th.hasClass("fieldset-label") && !isVisible(i)) {
            $($("td", $row).get(i)).hide();
          }
        });

        $currentRow.after($row);
        $(":input:visible:first", $row).focus();
      });

      $modal.off("keydown").on("keydown", function(event) {
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
              $(".add-row", $row).trigger("click");
              $(":input:visible:first", $("td", $row.next())[$cell.index()]).focus();
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

      $modal.on("click", "th.fieldset-label", function(event) {
        $(this).toggleClass("sticky");
        var sticky = [];
        $("table th.sticky", $this).each(function() {
          sticky.push($(this).index());
        });
        STICKY_COLUMN_INDEXES = sticky;
        $.cookie("rde.sticky", JSON.stringify(STICKY_COLUMN_INDEXES));
      });

      $modal.on("click", "[data-dismiss]", function(event) {
        $modal.modal("hide");
      });

      var initAjaxForm = function() {
        $this.ajaxForm({
          target: $(".rde-wrapper", $modal),
          success: function() {
            $(window).trigger("resize");
            $this = $("form", "#rapidDataEntryModal");
            $table = $("table", $this);

            if ($this.length) {
              $("tbody tr", $this).each(function() {
                var $row = $(this);
                if ($("td.error", $row).length > 0) {
                  $row.addClass("invalid");
                } else {
                  $row.addClass("valid");
                }
              });

              $("#form_messages .error[data-target]", $this).each(function() {
                // tweak the error message to match the column heading
                var $input = $("#"+$(this).data("target"));
                var $cell = $input.closest("td");
                var $row = $cell.closest("tr");
                var headerText = $($(".fieldset-labels th", $table).get($cell.index())).text();
                var newMessageText = $this.data("error-prefix") + " " + ($row.index()+1) + ": " + headerText + " - " + $(this).data("message");

                $(this).html(newMessageText);
                if ($(this).hasClass("linked-to-field")) {
                  $(this).append("<span class='icon-chevron-down'></span>");
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

        // add sorting
        $table.kiketable_colsizable({
          dragCells: "tr.fieldset-labels th.fieldset-label",
          dragMove: true
        });
        $("th.fieldset-label .kiketable-colsizable-handler", $table).on("dragend", persistColumnWidths);

        // add show/hide
        $table.columnManager();

        applyPersistentStickyColumns();
        initColumnShowHideWidget();
      };

      var initColumnShowHideWidget = function() {
        var $select = $("#rde_hidden_columns");
        $(".fieldset-labels th", $this).each(function() {
          if ($(this).hasClass("fieldset-label")) {
            var $option = $("<option>");
            $option.val($(this).index()).text($(this).text()).attr("selected", "selected");
            $select.append($option);
          }
        });
        $select.multiselect({
          buttonClass: 'btn btn-small',
          buttonWidth: 'auto',
          maxHeight: 300,
          buttonContainer: '<div class="btn-group" />',
          buttonText: function(options) {
            if (options.length == 0) {
              return $select.data("i18n-none") + ' <b class="caret"></b>';
            }
            else if (options.length > 5) {
              return $select.data("i18n-prefix") + ' ' + options.length + ' ' + $select.data("i18n-suffix") + ' <b class="caret"></b>';
            }
            else {
              var selected = $select.data("i18n-prefix") + " ";
              options.each(function() {
                selected += $(this).text() + ', ';
              });
              return selected.substr(0, selected.length -2) + ' <b class="caret"></b>';
            }
          },
          onChange: function($option, checked) {
            var widths = persistColumnWidths();
            var index = parseInt($option.val());

            if (checked) {
              $table.showColumns(index+1);
              var $col = $($("table colgroup col").get(index));
              $col.show();
              $table.width($table.width() + widths[index]);
            } else {
              hideColumn(index);
            }

            VISIBLE_COLUMN_INDEXES = $select.val();
            $.cookie("rde.visible", JSON.stringify(VISIBLE_COLUMN_INDEXES));
          }
        });

        applyPersistentVisibleColumns();
      };

      var persistColumnWidths = function() {
        var widths = [];
        $("table colgroup col", $this).each(function() {
          if ($(this).width() === 0) {
            $(this).width($(this).data("default-width"));
          }
          widths.push($(this).width());
        });

        COLUMN_WIDTHS = widths;
        $.cookie("rde.widths", JSON.stringify(COLUMN_WIDTHS));

        return COLUMN_WIDTHS;
      };

      var setColumnWidth = function(index) {
        var width = getColumnWidth(index);

        $($("table colgroup col", $this).get(index)).width(width);

        return width;
      };

      var getColumnWidth = function(index) {
        if ( COLUMN_WIDTHS ) {
          return COLUMN_WIDTHS[index];
        } else {
          persistColumnWidths();
          return getColumnWidth(index);
        }
      };

      var applyPersistentColumnWidths = function() {
        var total_width = 0;

        $("table colgroup col", $this).each(function(i, el) {
          var colW = getColumnWidth(i);
          $(el).width(colW);
          total_width += colW;
        });

        $table.width(total_width);
      };

      var applyPersistentStickyColumns = function() {
        if ( STICKY_COLUMN_INDEXES ) {
          $("th.sticky", $this).removeClass("sticky");
          $.each(STICKY_COLUMN_INDEXES, function() {
            $($(".fieldset-labels th", $this).get(this)).addClass("sticky");
          });
        }
      };

      var isVisible = function(index) {
        if ( VISIBLE_COLUMN_INDEXES ) {
          return  $.inArray(index+"", VISIBLE_COLUMN_INDEXES) >= 0
        } else {
          return true;
        }
      };

      var applyPersistentVisibleColumns = function() {
        if ( VISIBLE_COLUMN_INDEXES ) {
          var total_width = 0;

          $.each($(".fieldset-labels th", $this), function() {
            var index = $(this).index();

            if ($(this).hasClass("fieldset-label")) {
              if (isVisible(index)) {
                total_width += setColumnWidth(index);
              } else {
                hideColumn(index);
              }
            } else {
              total_width += setColumnWidth(index);
            }
          });
          $table.width(total_width);
        } else {
          applyPersistentColumnWidths();
        }
      };

      var hideColumn = function(index) {
        $("#rde_hidden_columns").multiselect('deselect', index+"");
        $table.hideColumns(index+1);
        var $col = $($("table colgroup col").get(index));
        $table.width($table.width() - $col.width());
        $col.hide();
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

  $(document).bind("rdeload.aspace", function(event, $node, $modal) {
    $.ajax({
      url: "/"+$node.attr("rel")+"s/"+$node.data("id")+"/rde",
      success: function(data) {
        $(".rde-wrapper", $modal).replaceWith("<div class='modal-body'></div>");
        $(".modal-body", $modal).replaceWith(data);
        $("form", "#rapidDataEntryModal").init_rapid_data_entry_form($modal, $node);
      }
    });
  });

  $(document).bind("rdeshow.aspace", function(event, $node, $button) {
    var $modal = AS.openCustomModal("rapidDataEntryModal", $button.text(), AS.renderTemplate("modal_content_loading_template"), 'full', {keyboard: false});

    $(document).triggerHandler("rdeload.aspace", [$node, $modal]);
  });

});