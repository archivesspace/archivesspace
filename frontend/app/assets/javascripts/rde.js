//= require jquery.event.drag-1.4.min
//= require jquery.kiketable.colsizable-1.1
//= require jquery.columnmanager.min
//= require bootstrap-multiselect
//= require linker

$(function() {

  $.fn.init_rapid_data_entry_form = function($modal, uri) {
    $(this).each(function() {
      var $rde_form = $(this);
      var $table = $("table#rdeTable", $rde_form);

      if ($rde_form.hasClass("initialised")) {
        return;
      }

      $(".linker:not(.initialised)").linker();

      // Cookie Names
      var COOKIE_NAME_VISIBLE_COLUMN = "rde."+$rde_form.data("cookie-prefix")+".visible";
      var COOKIE_NAME_STICKY_COLUMN = "rde."+$rde_form.data("cookie-prefix")+".sticky";
      var COOKIE_NAME_COLUMN_WIDTHS = "rde."+$rde_form.data("cookie-prefix")+".widths";
      var COOKIE_NAME_COLUMN_ORDER = "rde."+$rde_form.data("cookie-prefix")+".order";

      // Config from Cookies
      var VISIBLE_COLUMN_IDS =  AS.prefixed_cookie(COOKIE_NAME_VISIBLE_COLUMN) ? JSON.parse(AS.prefixed_cookie(COOKIE_NAME_VISIBLE_COLUMN)) : null;
      var STICKY_COLUMN_IDS =  AS.prefixed_cookie(COOKIE_NAME_STICKY_COLUMN) ? JSON.parse(AS.prefixed_cookie(COOKIE_NAME_STICKY_COLUMN)) : null;
      var COLUMN_WIDTHS =  AS.prefixed_cookie(COOKIE_NAME_COLUMN_WIDTHS) ? JSON.parse(AS.prefixed_cookie(COOKIE_NAME_COLUMN_WIDTHS)) : null;
      var COLUMN_ORDER =  AS.prefixed_cookie(COOKIE_NAME_COLUMN_ORDER) ? JSON.parse(AS.prefixed_cookie(COOKIE_NAME_COLUMN_ORDER)) : null;
      var DEFAULT_VALUES = {};

      // store section data
      var SECTION_DATA = {};
      $(".sections th", $table).each(function() {
        SECTION_DATA[$(this).data("id")] = $(this).text();
      });

      var validateSubmissionOnly = false;

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

        $(":input, .btn", $rde_form).attr("disabled", "disabled");

        // reset cookies
        AS.prefixed_cookie(COOKIE_NAME_VISIBLE_COLUMN, null);
        AS.prefixed_cookie(COOKIE_NAME_COLUMN_WIDTHS, null);
        AS.prefixed_cookie(COOKIE_NAME_STICKY_COLUMN, null);
        AS.prefixed_cookie(COOKIE_NAME_COLUMN_ORDER, null);
        VISIBLE_COLUMN_IDS = null;
        STICKY_COLUMN_IDS = null;
        COLUMN_WIDTHS = null;
        COLUMN_ORDER = null;

        // reload the form
        $(document).triggerHandler("rdeload.aspace", [uri, $modal]);
      });

      $modal.on("click", ".add-row", function(event) {
        event.preventDefault();
        event.stopPropagation();

        var $row = addRow(event);

        $(":input:visible:first", $row).focus();

        $(".linker:not(.initialised)").linker();

        validateRows($row);
      });


      var setRowIndex = function() {
        current_row_index = Math.max($("tbody tr", $table).length-1, 0);
        $("tbody tr", $table).each(function(i, row) {
          $(row).data("index", i);
        });
      };
      var current_row_index = 0;
      setRowIndex();


      var addRow = function(event) {

        var $currentRow = $(event.target).closest("tr");
        if ($currentRow.length === 0) {
          $currentRow = $("table tbody tr:last", $rde_form);
        }

        current_row_index = current_row_index+1;

        var $row = $(AS.renderTemplate("template_rde_"+$rde_form.data("child-type")+"_row", {
          path: $rde_form.data("jsonmodel-type") + "[children]["+current_row_index+"]",
          id_path: $rde_form.data("jsonmodel-type") + "_children__"+current_row_index+"_",
          index: current_row_index
        }));

        $row.data("index", current_row_index);

        $(".fieldset-labels th", $rde_form).each(function(i, th) {
          var $th = $(th);

          // Apply any sticky columns
          if ($currentRow.length > 0) {
            if ($th.hasClass("fieldset-label") && $th.hasClass("sticky")) {
              // populate the input from the current or bottom row
              var $source = $(":input:first", $("td", $currentRow).get(i));
              var $target = $(":input:first", $("td", $row).get(i));

              if ($source.is(":checkbox")) {
                if ($source.is(":checked")) {
                  $target.attr("checked", "checked");
                } else {
                  $target.removeAttr("checked");
                }
              } else if ($source.is(":hidden") && $source.parents().closest("div").hasClass("linker-wrapper")) {
                // a linker!
                $target.attr("data-selected", $source.val());
              } else if ($source.is('.linker:text')) {
                // $source is a yet to be initialized linker (when adding multiple rows)
                $target.attr("data-selected", $source.attr("data-selected"));
              } else {
                $target.val($source.val());
              }
            } else if (DEFAULT_VALUES[$th.attr('id')]) {
              var $target = $(":input:first", $("td", $row).get(i));
              $target.val(DEFAULT_VALUES[$th.attr('id')]);
            }
          }

          // Apply hidden columns
          if ($th.hasClass("fieldset-label") && !isVisible($th.attr("id"))) {
            $($("td", $row).get(i)).hide();
          }

          // Apply column order
          if (COLUMN_ORDER != null) {
            $.each(COLUMN_ORDER, function(targetIndex, colId) {
              var $td = $("td[data-col='"+colId+"']", $row);
              var currentIndex = $td.index();

              if (targetIndex !== currentIndex) {
                $td.insertBefore($("td", $row).get(targetIndex));
              }
            });
          }
        });

        $currentRow.after($row);
        initOtherLevelHandler(current_row_index);
        return $row;
      };

      $modal.off("keydown").on("keydown", function(event) {
        if (event.keyCode === 27) { //esc
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      });

      // TODO - use hotkeys for this?
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
            $(":input:visible:first", prevActiveCell($cell)).focus();
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
            $(":input:visible:first", nextActiveCell($cell)).focus();
          }
        } else {
          // we're cool.
        }
      });

      $modal.on("click", "th.fieldset-label", function(event) {
        $(this).toggleClass("sticky");
        var sticky = [];
        $("table th.sticky", $rde_form).each(function() {
          sticky.push($(this).attr("id"));
        });
        STICKY_COLUMN_IDS = sticky;
        AS.prefixed_cookie(COOKIE_NAME_STICKY_COLUMN, JSON.stringify(STICKY_COLUMN_IDS));
      });

      $modal.on("click", "[data-dismiss]", function(event) {
        $modal.modal("hide");
      });

      var renderInlineErrors = function($rows, exception_data) {
        $(".linker:not(.initialised)").linker();
        $rows.each(function(i, row) {
          var $row = $(row);
          var row_result = exception_data[i];
          var $errorSummary = $(".error-summary", $row);
          var $errorSummaryList = $(".error-summary-list", $errorSummary)

          $errorSummaryList.empty();

          if (row_result.hasOwnProperty("errors") && !$.isEmptyObject(row_result.errors)) {
            $row.removeClass("valid").addClass("invalid");

            $.each(row_result.errors, function(name, error) {
              var $input = $("[id='"+$rde_form.data("jsonmodel-type")+"_children__"+$row.data("index")+"__"+name.replace(/\//g, "__")+"_']", $row);
              var $header = $($(".fieldset-labels th", $table).get($input.first().closest("td").index()));

              $input.closest(".form-group").addClass("has-error");

              var $error = $("<div class='error'>");

              if ($input.length > 1 || $input.hasClass("defer-to-section")) {
                $error.text(SECTION_DATA[$header.data("section")]);
              } else {
                $error.text($($(".fieldset-labels th", $table).get($input.closest("td").index())).text());
              }
              $error.append(" - ").append(error);
              $error.append("<span class='glyphicon glyphicon-chevron-right'>");
              $errorSummaryList.append($error);

              $error.data("target", $input.first().attr("id"));
            });

            // force a reposition of the error summary
            $(".modal-body", $modal).trigger("scroll");
          } else {
            $row.removeClass("invalid").addClass("valid");
          }
        });
      };

      var initAjaxForm = function() {
        $rde_form.ajaxForm({
          target: $(".rde-wrapper", $modal),
          success: function() {
            $(window).trigger("resize");
            $rde_form = $("form", "#rapidDataEntryModal");
            $table = $("table", $rde_form);

            setRowIndex();

            if ($rde_form.length) {
              renderInlineErrors($("tbody tr", $rde_form), $rde_form.data("exceptions"));

              initAjaxForm();
            } else {
              // we're good to go!
              setTimeout(function() {
                location.reload(true);
              }, 1000);
            }
          }
        });

        // add ability to resize columns
        $table.kiketable_colsizable({
          dragCells: "tr.fieldset-labels th.fieldset-label",
          dragMove: true
        });
        $("th.fieldset-label .kiketable-colsizable-handler", $table).on("dragend", persistColumnWidths);

        // add show/hide
        $table.columnManager();

        // give the columns an id
        $("table thead .fieldset-labels th").each(function(i, col) {
          if (!$(col).attr("id")) {
            $(col).attr("id", "rdecol"+i);
          }
          $($("table colgroup col").get(i)).data("id", $(col).attr("id"));
        });

        initAutoValidateFeature();
        applyColumnOrder();
        initColumnReorderFeature();
        initRdeTemplates();
        applyPersistentStickyColumns();
        initColumnShowHideWidget();
        initFillFeature();
        initShowInlineErrors();
        initOtherLevelHandler();
      };


      var initShowInlineErrors = function() {
        if ($("button.toggle-inline-errors").hasClass("active")) {
          $table.addClass("show-inline-errors");
        } else {
          $table.removeClass("show-inline-errors");
        }
      };


      var initOtherLevelHandler = function(index) {
        var index = index || 0;
        var $select = $("td[data-col='colLevel']:eq("+index+") select");

        if($select.val() === 'otherlevel') {
          enableCell("colOtherLevel", index);
        } else {
          disableCell("colOtherLevel", index);
        }

        $select.change(function() {
          if ($(this).val() === 'otherlevel') {
            enableCell("colOtherLevel", index);
          } else {
            disableCell("colOtherLevel", index);
          }
        });
      }


      var initAutoValidateFeature = function() {
        // Validate row upon input change
        $table.on("change", ":input:visible", function() {
          var $row = $(this).closest("tr");
          validateRows($row);
        });
        $(".modal-body", $modal).on("scroll", function(event) {
          $(".error-summary", $table).css("left", $(this)[0].scrollLeft + 5);
        });
        $table.on("focusin click", ":input", function() {
          $(this).closest("tr").addClass("last-focused").siblings().removeClass("last-focused");
        });
        $table.on("click", ".error-summary .error", function() {
          var $target = $("#"+$(this).data("target"));

          // if column is hidden, then show the column first
          if (!$target.is("visible")) {
            var colId = COLUMN_ORDER[$target.closest("td").index()];
            $("#rde_hidden_columns").multiselect("select", colId);
          }

          $target.closest("td").ScrollTo({
            axis: 'x',
            callback: function() {
              $target.focus();
            }
          });
        });
        $table.on("click", "td.status", function(event) {
          event.preventDefault();
          event.stopPropagation();

          if ($(event.target).closest(".error-summary").length > 0) {
            // don't propagate to the status cell
            // if clicking on an error
            return;
          }

          if ($(this).closest("tr").hasClass("last-focused")) {
            $("button.toggle-inline-errors").trigger("click");
          } else {
            $(this).closest("tr").addClass("last-focused").siblings().removeClass("last-focused");
          }
        });
        $table.on("click", ".hide-error-summary, .show-error-summary", function(event) {
          event.preventDefault();
          event.stopPropagation();

          $("button.toggle-inline-errors").trigger("click");
        });
      };

      var initFillFeature = function() {
        var $fillFormsContainer = $(".fill-column-form", $modal);
        var $btnFillFormToggle = $("button.fill-column", $modal);

        var $sourceRow = $("table tbody tr:first", $rde_form);

        // Setup global events
        $btnFillFormToggle.click(function(event) {
          event.preventDefault();
          event.stopPropagation();

          // toggle other panel if it is active
          if (!$(this).hasClass("active")) {
            $(".active", $(this).closest(".btn-group")).trigger("click");
          }

          $btnFillFormToggle.toggleClass("active");
          $fillFormsContainer.slideToggle();
        });

        // Setup Basic Fill form
        var setupBasicFillForm = function() {
          var $form = $("#fill_basic", $fillFormsContainer);
          var $inputTargetColumn = $("#basicFillTargetColumn", $form);
          var $btnFill = $("button", $form);

          // populate the column selectors
          populateColumnSelector($inputTargetColumn);

          $inputTargetColumn.change(function() {
            $(".empty", this).remove();

            var colIndex = parseInt($("#"+$(this).val()).index());

            var $input = $(":input:first", $("td", $sourceRow).get(colIndex)).clone();
            $input.attr("name", "").attr("id", "basicFillValue");
            $(".fill-value-container", $form).html($input);
            $btnFill.removeAttr("disabled").removeClass("disabled");
          });

          $btnFill.click(function(event) {
            event.preventDefault();
            event.stopPropagation();

            var colIndex = parseInt($("#"+$inputTargetColumn.val()).index())+1;

            var $targetCells = $("table tbody tr td:nth-child("+colIndex+")", $rde_form);

            if ($("#basicFillValue",$form).is(":checkbox")) {
              var fillValue = $("#basicFillValue",$form).is(":checked");
              if (fillValue) {
                $(":input:first", $targetCells).attr("checked", "checked");
              } else {
                $(":input:first", $targetCells).removeAttr("checked");
              }
            } else {
              var fillValue = $("#basicFillValue",$form).val();
              $(":input:first", $targetCells).val(fillValue);
            }

            $btnFillFormToggle.toggleClass("active");
            $fillFormsContainer.slideToggle();
            validateAllRows();
          });
        };

        // Setup Sequence Fill form
        var setupSequenceFillForm = function() {
          var $form = $("#fill_sequence", $fillFormsContainer);
          var $inputTargetColumn = $("#sequenceFillTargetColumn", $form);
          var $btnFill = $("button.btn-primary", $form);
          var $sequencePreview = $(".sequence-preview", $form);

          // populate the column selectors
          populateColumnSelector($inputTargetColumn, null, function($colHeader) {
            var $td = $("td", $sourceRow).get($colHeader.index());
            return $(":input:first", $td).is(":text");
          });

          $inputTargetColumn.change(function() {
            $(".empty", this).remove();
            $btnFill.removeAttr("disabled").removeClass("disabled");
          });

          $("button.preview-sequence", $form).click(function(event) {
            event.preventDefault();
            event.stopPropagation();

            $.getJSON($form.data("sequence-generator-url"),
                      {
                        prefix: $("#sequenceFillPrefix", $form).val(),
                        from: $("#sequenceFillFrom", $form).val(),
                        to: $("#sequenceFillTo", $form).val(),
                        suffix: $("#sequenceFillSuffix", $form).val(),
                        limit: $("tbody tr", $table).length
                      },
                      function(json) {
                        $sequencePreview.html("");
                        if (json.errors) {
                          $.each(json.errors, function(i, error) {
                            var $error = $("<div>").html(error).addClass("text-error");
                            $sequencePreview.append($error);
                          });
                        } else {
                          $sequencePreview.html($("<p class='values'>").html(json.values.join(", ")));
                          $sequencePreview.prepend($("<p class='summary'>").html(json.summary));
                        }
                      }
            );
          });

          var applySequenceFill = function(force) {
            $("#sequenceTooSmallMsg", $form).hide();

            $.getJSON($form.data("sequence-generator-url"),
                {
                  prefix: $("#sequenceFillPrefix", $form).val(),
                  from: $("#sequenceFillFrom", $form).val(),
                  to: $("#sequenceFillTo", $form).val(),
                  suffix: $("#sequenceFillSuffix", $form).val(),
                  limit: $("tbody tr", $table).length
                },
                function(json) {
                  $sequencePreview.html("");
                  if (json.errors) {
                    $.each(json.errors, function(i, error) {
                      var $error = $("<div>").html(error).addClass("text-error");
                      $sequencePreview.append($error);
                    });
                    return;
                  }

                  // check if less items in sequence than rows
                  if (!force && json.values.length < $("tbody tr", $modal).length) {
                    $("#sequenceTooSmallMsg", $form).show();
                    return;
                  }

                  // Good to go. Apply values.
                  var targetIndex = $("#"+$inputTargetColumn.val()).index();
                  var $targetCells = $("table tbody tr td:nth-child("+(targetIndex+1)+")", $rde_form);
                  $.each(json.values, function(i, val) {
                    if (i > $targetCells.length) {
                      return;
                    }
                    $(":input:first", $targetCells[i]).val(val);
                  });

                  $btnFillFormToggle.toggleClass("active");
                  $fillFormsContainer.slideToggle();
                  validateAllRows();
                }
            );
          }

          $btnFill.click(function(event) {
            event.preventDefault();
            event.stopPropagation();

            applySequenceFill(false);
          });

          $(".btn-continue-sequence-fill", $form).click(function(event) {
            event.preventDefault();
            event.stopPropagation();

            applySequenceFill(true);
          });
        };

        setupBasicFillForm();
        setupSequenceFillForm();
      };

      var persistColumnOrder = function() {
        var column_ids = [];
        $("table .fieldset-labels th", $rde_form).each(function() {
          column_ids.push($(this).attr("id"));
        });
        COLUMN_ORDER = column_ids;
        AS.prefixed_cookie(COOKIE_NAME_COLUMN_ORDER, JSON.stringify(COLUMN_ORDER));
      };

      var applyColumnOrder = function() {
        if (COLUMN_ORDER === null) {
          persistColumnOrder();
        } else {
          // apply order from cookie
          var $row = $("tr.fieldset-labels", $table);
          var $sectionRow = $("tr.sections", $table);
          var $colgroup = $("colgroup", $table);

          $sectionRow.html("");

          $.each(COLUMN_ORDER, function(targetIndex, colId) {
            var $th = $("#" + colId, $row);
            var currentIndex = $th.index();
            var $col = $($("col", $colgroup).get(currentIndex));

            // show hidden stuff so we get the section headers right
            // we'll reapply visibility at the end
            if (!isVisible(colId) && targetIndex > 0) {
              showColumn(currentIndex);
            }

            if (targetIndex !== currentIndex) {
                $th.insertBefore($("th", $row).get(targetIndex));
                $col.insertBefore($("col", $colgroup).get(targetIndex));
                $("tbody tr", $table).each(function(i, $tr) {
                  $($("td", $tr).get(currentIndex)).insertBefore($("td", $tr).get(targetIndex));
                });
            }

            // build the section row cells
            if (targetIndex === 0) {
              $sectionRow.append($("<th>").data("id", "empty").attr("colspan", "1"));
            } else if ($("th", $sectionRow).last().data("id") === $th.data("section")) {
              var $lastTh = $("th", $sectionRow).last();
              $lastTh.attr("colspan", parseInt($lastTh.attr("colspan"))+1);
            } else {
              $sectionRow.append($("<th>").data("id", $th.data("section")).addClass("section-"+$th.data("section")).attr("colspan", "1").text(SECTION_DATA[$th.data("section")]));
            }
          });

          applyPersistentVisibleColumns()
        }
      };


      var templateList = null;
      var initRdeTemplates = function() {
        initSaveTemplateFeature();
        loadRdeTemplateList(function() {
          initManageTemplatesFeature();
          initSelectTemplateFeature();
        });
      };

      var loadRdeTemplateList = function(cb) {
        var recordType = $rde_form.data("child-type");

        $.ajax({
          url: $rde_form.data("list-templates-uri"),
          type: 'GET',
          dataType: 'json',
          success: function(_templateList_) {
            templateList = _.filter(_templateList_, function(t) {
              return t.record_type === recordType;
            });
            cb();
          },
          error: function(xhr, status, err) {
            console.log(err);
          }
        });
      };


      var initSaveTemplateFeature = function() {
        var $saveContainer = $("#saveTemplateForm", $modal);
        var $containerToggle = $("button.save-template", $modal);
        var $input = $("#templateName", $saveContainer);
        var $btnSave = $(".btn-primary", $saveContainer);

        // Setup global events
        $containerToggle.off("click").on("click", function(event) {
          event.preventDefault();
          event.stopPropagation();

          // toggle other panel if it is active
          if (!$(this).hasClass("active")) {
            $(".active", $(this).closest(".btn-group")).trigger("click");
          }

          $containerToggle.toggleClass("active");
          $saveContainer.slideToggle();
        });

        $input.on('change keyup paste', function() {
          if ($(this).val().length > 0) {
            $btnSave.removeAttr("disabled").removeClass("disabled");
          } else {
            $btnSave.prop('disabled', true);
          }
        });

        $btnSave.click(function(event) {
          event.preventDefault();
          event.stopPropagation();

          var template = {
            record_type: $rde_form.data("child-type"),
            name: $input.val(),
            order: [],
            visible: [],
            defaults: {},
          }

          var $firstRow = $("table tbody tr:first", $rde_form);

         $("table .fieldset-labels th", $rde_form).each(function() {
            var colId = $(this).attr("id");

            template.order.push(colId);
            if ($(this).is(":visible")) {
              template.visible.push(colId);
            }

            var $cellOne =  $("td[data-col='"+colId+"']", $firstRow);

           if ($("input", $cellOne).length) {
             template.defaults[colId] = $("input", $cellOne).val();
           } else if ($("select", $cellOne).length) {
             template.defaults[colId] = $("select", $cellOne).val();
           }


          });

          template.defaults = _.pick(template.defaults, function(n) {
            return n.length > 0;
          });

          $.ajax({
            url: $rde_form.data("save-template-uri"),
            type: "POST",
            data: {template: template},
            dataType: "json",
            success: function(data) {
              loadRdeTemplateList(function() {
                initManageTemplatesFeature();
                initSelectTemplateFeature();
              });
              $containerToggle.toggleClass("active");
              $saveContainer.slideToggle();
            },
            error: function(xhr, status, err) {
              console.log(err);
            }
          });

        });
      };


      var initManageTemplatesFeature = function() {
        var $manageContainer = $("#manageTemplatesForm", $modal);
        var $containerToggle = $("button.manage-templates", $modal);

        var $templatesTable = $('table tbody', $manageContainer);

        $containerToggle.off("click").on("click", function(event) {
          event.preventDefault();
          event.stopPropagation();

          // toggle other panel if it is active
          if (!$(this).hasClass("active")) {
            $(".active", $(this).closest(".btn-group")).trigger("click");
          }

          $templatesTable.empty();
          renderTable();
          $containerToggle.toggleClass("active");
          $manageContainer.slideToggle();
        });


        $("button.btn-cancel", $manageContainer).off("click").on("click", function(e) {
          e.preventDefault();
          e.stopPropagation();
          $containerToggle.toggleClass("active");
          $manageContainer.slideToggle();
        });


        $("button.btn-primary", $manageContainer).off("click").on("click", function(e) {
          e.preventDefault();
          e.stopPropagation();

          var templatesToDelete = [];
          $manageContainer.find(":checkbox:checked").each(function(){
            templatesToDelete.push($(this).val());
          });

          $.ajax({
            url: $rde_form.data("list-templates-uri") + "/batch_delete",
            type: 'POST',
            dataType: 'json',
            data: {ids: templatesToDelete},
            success: function(updatedTemplateList) {
              templateList = updatedTemplateList;
              initSelectTemplateFeature();
            },
            error: function(xhr, status, err) {
              console.log(err);
            }
          });

          $containerToggle.toggleClass("active");
          $manageContainer.slideToggle();
        });


        var renderTable = function() {
          if (templateList.length == 0) {
            $(".no-templates-message", $manageContainer).show();
            $(".btn-primary", $manageContainer).hide();
            return;
          } else {
            $(".no-templates-message", $manageContainer).hide();
            $(".btn-primary", $manageContainer).show();
          }

          _.each(templateList, function(item) {
            $templatesTable.append(AS.renderTemplate("rde_template_table_row", {item: item}));
          });
        };


        $.ajax({
          url: $rde_form.data("list-templates-uri"),
          type: 'GET',
          dataType: 'json',
          success: function(_templateList_) {
            templateList = _templateList_;
          }
        });
      };


      var applyTemplate = function(template) {
        COLUMN_ORDER = template.order;
        VISIBLE_COLUMN_IDS = template.visible;
        DEFAULT_VALUES = template.defaults;

        applyColumnOrder();

        var $firstRow = $("tbody tr:first", $rde_form);

        _.each($("td", $firstRow), function(td) {
          var $td = $( td );
          var colId = $td.data('col');
          var $$input = $(":input:first", $td)
          if (DEFAULT_VALUES[colId] && ($$input.data('value-from-template') || $$input.val().length < 1)) {
            $$input.val(DEFAULT_VALUES[colId]);
            $$input.data('value-from-template', true);
          }
        });
      };


      var initSelectTemplateFeature = function() {

        var $select = $("#rde_select_template");

        $select.change(function() {
          var id = $("option:selected", $select).val();
          $.ajax({
            url: $rde_form.data("template-base-uri") + "/" + id,
            type: 'GET',
            dataType: 'json',
            success: function(template) {
              applyTemplate(template);
              $select.attr('data-style', 'btn-success');
              $select.selectpicker('refresh');
            }
          });


        });

        var renderOptions = function() {
          $select.empty();

          $select.append($("<option>", {disabled : "disabled" , selected: 'selected'})
                         .text($select.data('prompt-text')));

          _.each(templateList, function(item) {

            $select.append($("<option>", {value : item.id })
                           .text(item.name));

          });

          $select.selectpicker('refresh');
        };

        renderOptions();
      };


      var initColumnReorderFeature = function() {
        var $reorderContainer = $("#columnReorderForm", $modal);
        var $btnReorderToggle = $("button.reorder-columns", $modal);
        var $select = $("#columnOrder", $reorderContainer);
        var $btnApplyOrder = $(".btn-primary", $reorderContainer);


        // Setup global events
        $btnReorderToggle.off("click").on("click", function(event) {
          event.preventDefault();
          event.stopPropagation();

          // toggle other panel if it is active
          if (!$(this).hasClass("active")) {
            $(".active", $(this).closest(".btn-group")).trigger("click");
          }

          $btnReorderToggle.toggleClass("active");
          $reorderContainer.slideToggle();
        });

        populateColumnSelector($select);
        $select.attr("size", $("option", $select).length / 2);

        var handleMove = function(direction) {
          var $options = $("option:selected", $select);
          if ($options.length) {
            if (direction === "up") {
              $options.first().prev().before($options);
            } else {
              $options.last().next().after($options);
            }
          }
          $btnApplyOrder.removeAttr("disabled").removeClass("disabled");
        };

        var resetForm = function() {
          $btnReorderToggle.toggleClass("active");
          $reorderContainer.slideToggle(function() {
            $btnApplyOrder.addClass("disabled").attr("disabled", "disabled");
            // reset the select
            $select.html("");
            populateColumnSelector($select);
          });
        }

        $('#columnOrderUp', $reorderContainer).bind('click', function() {
          handleMove("up");
        });
        $('#columnOrderDown', $reorderContainer).bind('click', function() {
          handleMove("down");
        });
        $(".btn-cancel", $reorderContainer).click(function(event) {
          event.preventDefault();
          event.stopPropagation();

          resetForm();
        });
        $btnApplyOrder.click(function(event) {
          event.preventDefault();
          event.stopPropagation();

          COLUMN_ORDER = ["colStatus"];
          $("option", $select).each(function() {
            COLUMN_ORDER.push($(this).val());
          });
          COLUMN_ORDER.push("colActions");

          applyColumnOrder();
          resetForm();
          persistColumnOrder();
        });
      };

      var populateColumnSelector = function($select, select_func, filter_func) {
        filter_func = filter_func || function() {return true;};
        select_func = select_func || function() {return false;};
        $(".fieldset-labels th", $rde_form).each(function() {
          var $colHeader = $(this);
          if ($colHeader.hasClass("fieldset-label") && filter_func($colHeader)) {
            var $option = $("<option>");
            var option_text = "";
            option_text += $(".section-"+$colHeader.data("section")+":first").text();
            option_text += " - ";
            option_text += $colHeader.text();

            $option.val($colHeader.attr("id")).text(option_text);
            if (select_func($colHeader)) {
              $option.attr("selected", "selected");
            }
            $select.append($option);
          }
        });
      };

      var initColumnShowHideWidget = function() {
        var $select = $("#rde_hidden_columns");
        populateColumnSelector($select, function($colHeader) {
          return isVisible($colHeader.attr("id"));
        });
        $select.multiselect({
          buttonClass: 'btn btn-small btn-default',
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
            var colId = $option.val();
            var index = $("#" + colId).index();

            if (checked) {
              $table.showColumns(index+1);
              var $col = $($("table colgroup col").get(index));
              $col.show();
              $table.width($table.width() + widths[index]);
            } else {
              hideColumn(index);
            }

            VISIBLE_COLUMN_IDS = $select.val();
            AS.prefixed_cookie(COOKIE_NAME_VISIBLE_COLUMN, JSON.stringify(VISIBLE_COLUMN_IDS));
          }
        });
        
        function disableRequiredColumns() {
          // Don't allow omitting required fields in RDE templates
          // by disabling the bootstratp-multiselect.js generated
          // list items and checkboxes that represent required RDE columns
          var $requiredColumns = $.makeArray($(".fieldset-labels th.required", $rde_form));

          $requiredColumns.forEach(function(column) {
            var id = column.id;
            var checkboxSelector = "input[type='checkbox'][value=" + id + "]";
            var $li = $("li").has(checkboxSelector);
            var $input = $(checkboxSelector);
            $li.addClass("disabled");
            $input.prop({ disabled: true });
          })
        }

        disableRequiredColumns();
        applyPersistentVisibleColumns();
      };

      var persistColumnWidths = function() {
        var widths = {};
        $("table colgroup col", $rde_form).each(function(i, col) {
          if ($(col).prop("width") === null || $(col).prop("width") === "") {
            $(col).prop("width", $(col).data("default-width"));
          } else if ($(col).css("width")) {
            var newWidth = parseInt($(col).css("width"));
            $(col).prop("width", newWidth);
          }
          widths[$(col).data("id")] = parseInt($(col).prop("width"));
        });

        COLUMN_WIDTHS = widths;
        AS.prefixed_cookie(COOKIE_NAME_COLUMN_WIDTHS, JSON.stringify(COLUMN_WIDTHS));

        return COLUMN_WIDTHS;
      };

      var setColumnWidth = function(colId) {
        var width = getColumnWidth(colId);
        var index = $("#"+colId).index();

        // set width of corresponding col element
        $($("table colgroup col", $rde_form).get(index)).width(width);

        return width;
      };

      var getColumnWidth = function(colId) {
        if ( COLUMN_WIDTHS ) {
          return COLUMN_WIDTHS[colId];
        } else {
          persistColumnWidths();
          return getColumnWidth(colId);
        }
      };

      var applyPersistentColumnWidths = function() {
        var total_width = 0;

        // force table layout to auto
        $table.css("tableLayout", "auto");

        $("colgroup col", $table).each(function(i, el) {
          var colW = getColumnWidth($(el).data("id"));
          $(el).prop("width", colW);
          total_width += colW;
        });

        $table.width(total_width);

        // and then change table layout to fixed to force a redraw to
        // ensure all colgroup widths are obeyed
        $table.css("tableLayout", "fixed");
      };

      var applyPersistentStickyColumns = function() {
        if ( STICKY_COLUMN_IDS ) {
          $("th.sticky", $rde_form).removeClass("sticky");
          $.each(STICKY_COLUMN_IDS, function() {
            $("#" + this).addClass("sticky");
          });
        }
      };

      var isVisible = function(colId) {
        if ( VISIBLE_COLUMN_IDS ) {
          return  $.inArray(colId, VISIBLE_COLUMN_IDS) >= 0
        } else {
          return true;
        }
      };

      var applyPersistentVisibleColumns = function() {
        if ( VISIBLE_COLUMN_IDS ) {
          var total_width = 0;

          $.each($(".fieldset-labels th", $rde_form), function() {
            var colId = $(this).attr("id");
            var index = $(this).index();

            if ($(this).hasClass("fieldset-label")) {
              if (isVisible(colId)) {
                total_width += setColumnWidth(colId);
              } else {
                hideColumn(index);
              }
            } else {
              total_width += setColumnWidth(colId);
            }
          });
          $table.width(total_width);
        } else {
          applyPersistentColumnWidths();
        }
      };

      var hideColumn = function(index) {
        $table.hideColumns(index+1);
        var $col = $($("table colgroup col").get(index));
        $table.width($table.width() - $col.width());
        $col.hide();
      };


      var showColumn = function(index) {
        $table.showColumns(index+1);
        var $col = $($("table colgroup col").get(index));
        $table.width($table.width() + $col.width());
        $col.show();
      }

      var enableCell = function(colId, rowIndex) {
        var row = $("tbody tr")[rowIndex];
        var cell = $("td[data-col='"+colId+"']", row);

        cell.removeClass("disabled");
        $('input', cell).removeAttr("disabled");
      }

      var disableCell = function(colId, rowIndex) {
        var row = $("tbody tr")[rowIndex];
        var cell = $("td[data-col='"+colId+"']", row);

        cell.addClass("disabled");
        $('input', cell).attr("disabled", "disabled");
      };

      var prevActiveCell = function($cell) {
        var prev = $cell.prev();
        if (prev.hasClass('disabled')) {
          return prevActiveCell(prev);
        } else {
          return prev;
        }
      };


      var nextActiveCell = function($cell) {
        var next = $cell.next();
        if (next.hasClass('disabled')) {
          return nextActiveCell(next);
        } else {
          return next;
        }
      };


      var validateAllRows = function() {
        validateRows($("tbody tr", $table));
      };

      var validateRows = function($rows) {
        var row_data = $rows.serializeObject();

        row_data["validate_only"] = "true";

        $(".error", $rows).removeClass("error");

        $.ajax({
          url: $rde_form.data("validate-row-uri"),
          type: "POST",
          data: row_data,
          dataType: "json",
          success: function(data) {
            renderInlineErrors($rows, data);
          }
        });
      };

      // Connect up the $modal form submit button
      $($modal).on("click", ".modal-footer .btn-primary", function() {
        $(this).attr("disabled","disabled");
        $rde_form.submit();
      });

      // Connect up the $modal form validate button
      $($modal).on("click", "#validateButton", function(event) {
        event.preventDefault();
        event.stopPropagation();

        validateSubmissionOnly = true;
        $(this).attr("disabled","disabled");
        $rde_form.append("<input type='hidden' name='validate_only' value='true'>");
        $rde_form.submit();
      });

      // enable form within the add row dropdown menu
      $(".add-rows-form input", $modal).click(function(event) {
        event.preventDefault();
        event.stopPropagation();
      });
      $(".add-rows-form button", $modal).click(function(event) {
        var rows = [];
        try {
          var numberOfRows = parseInt($("input", $(this).closest('.add-rows-form')).val(), 10);
          for (var i=1; i<=numberOfRows; i++) {
            rows.push(addRow(event));
          }
        } catch(e) {
          // if the field cannot parse the form value to an integer.. just quietly judge the user
        }
        validateRows($(rows));
      });

      // Connect the Inline Errors toggle
      $modal.on("click", "button.toggle-inline-errors", function(event) {
        event.preventDefault();
        event.stopPropagation();

        $(this).toggleClass("active");
        $table.toggleClass("show-inline-errors");
      });

      $modal.on("keyup", "button", function(event) {
        // pass on Return key hits as a click
        if (event.keyCode === 13) {
          $(this).trigger("click");
        }
      });

      $(document).triggerHandler("loadedrecordform.aspace", [$rde_form]);

      initAjaxForm();

      $(window).trigger("resize");

      // auto-validate the first row
      setTimeout(function() {
        validateAllRows();
      });
    });

    $("select.selectpicker", $modal).selectpicker();
  };

  $(document).bind("rdeload.aspace", function(event, uri, $modal) {
    var path = uri.replace(/^\/repositories\/[0-9]+\//, '');

    $.ajax({
      url: AS.app_prefix(path+"/rde"),
      success: function(data) {
        $(".rde-wrapper", $modal).replaceWith("<div class='modal-body'></div>");
        $(".modal-body", $modal).replaceWith(data);
        $("form", "#rapidDataEntryModal").init_rapid_data_entry_form($modal, uri);
      }
    });
  });

  $(document).bind("rdeshow.aspace", function(event, $node, $button) {
    var $modal = AS.openCustomModal("rapidDataEntryModal", $button.text(), AS.renderTemplate("modal_content_loading_template"), 'full', {backdrop: 'static', keyboard: false}, $button);

    $(document).triggerHandler("rdeload.aspace", [$node.data('uri'), $modal]);
  });

});
