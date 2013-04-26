//= require jquery.tokeninput

$(function() {
  $.fn.linker = function() {
    $(this).each(function() {
      var $this = $(this);
      var $linkerWrapper = $this.parents(".linker-wrapper:first");

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var config = {
        url: $this.data("url"),
        format_template: $this.data("format_template"),
        format_template_id: $this.data("format_template_id"),
        format_property: $this.data("format_property"),
        path: $this.data("path"),
        name: $this.data("name"),
        multiplicity: $this.data("multiplicity") || "many",
        label: $this.data("label"),
        label_plural: $this.data("label_plural"),
        modal_id: $this.data("modal_id") || ($this.attr("id") + "_modal"),
        sortable: $this.data("sortable") === true,
        types: $this.data("types"),
        exclude_ids: $this.data("exclude") || []
      };

      if (config.format_template && config.format_template.substring(0,2) != "${") {
        config.format_template = "${" + config.format_template + "}";
      }

      var renderItemsInModal = function(page) {
        page = page || 1;

        var currentlySelectedIds = [];
        $.each($this.tokenInput("get"), function(obj) {currentlySelectedIds.push(obj.id);});

        $.ajax({
          url: config.url,
          data: {
            page: page,
            type: config.types,
            q: "*"
          },
          type: "GET",
          dataType: "json",
          success: function(json) {
            $("#"+config.modal_id).find(".linker-list").html(AS.renderTemplate("linker_browse_template", {search_data: json.search_data, config: config, selected: currentlySelectedIds}));
          }
        });
      };


      var formattedNameForJSON = function(json) {
        if (config.format_template) {
          return AS.quickTemplate(config.format_template, json);
        } else if (config.format_template_id) {
          return $(AS.renderTemplate(config.format_template_id, json)).html();
        } else if (config.format_property) {
          return json[config.format_property];
        }
        return "ERROR: no format for name (formattedNameForJSON)"
      };

      var renderCreateFormForObject = function(form_uri) {
        var $modal = $("#"+config.modal_id);

        var initCreateForm = function(formEl) {
          $(".linker-container", $modal).html(formEl);
          $("#createAndLinkButton", $modal).removeAttr("disabled");
          $("form", $modal).ajaxForm({
            data: {
              inline: true
            },
            beforeSubmit: function() {
              $("#createAndLinkButton", $modal).attr("disabled","disabled");
            },
            success: function(response, status, xhr) {
              if ($(response).is("form")) {
                initCreateForm(response);
              } else {
                if (config.multiplicity === "one") {
                  clearTokens();
                }

                $this.tokenInput("add", {
                  id: response.uri,
                  name: formattedNameForJSON(response),
                  json: response
                });
                $this.parents("form:first").triggerHandler("form-changed");
                $modal.modal("hide");
              }
            }, 
            error: function(obj, errorText, errorDesc) {
              $("#createAndLinkButton", $modal).removeAttr("disabled");
            }
          });
        };

        $.ajax({
          url: form_uri,
          success: initCreateForm
        });
        $("#createAndLinkButton", $modal).click(function() {
          $("form", $modal).triggerHandler("submit");
        });
      };


      var showLinkerCreateModal = function() {
        AS.openCustomModal(config.modal_id, "Create "+ config.label, AS.renderTemplate("linker_createmodal_template", config));
        if ($(this).hasClass("linker-create-btn")) {
          renderCreateFormForObject($(this).data("target"));
        } else {
          renderCreateFormForObject($(".linker-create-btn:first", $linkerWrapper).data("target"));
        }
        return false; // IE8 patch
      };


      var addSelected = function() {
        selectedItems  = [];
        $(".token-input-delete-token", $linkerWrapper).each(function() {
          $(this).triggerHandler("click");
        });
        $(".linker-list :input:checked", "#"+config.modal_id).each(function() {
          var item = $(this).data("object");
          $this.tokenInput("add", {
            id: $(this).val(),
            name: formattedNameForJSON(item),
            json: item
          });
        });
        $("#"+config.modal_id).modal('hide');
        $this.parents("form:first").triggerHandler("form-changed");
      };


      var showLinkerBrowseModal = function() {
        AS.openCustomModal(config.modal_id, "Browse "+ config.label_plural, AS.renderTemplate("linker_browsemodal_template",config));
        renderItemsInModal();
        $("#"+config.modal_id).on("click","#addSelectedButton", addSelected);
        $("#"+config.modal_id).on("click", ".linker-list .pagination .navigation a", function() {
          renderItemsInModal($(this).attr("rel"));
        });
        return false; // IE patch
      };


      var formatResults = function(searchData) {
        var formattedResults = [];

        var currentlySelectedIds = [];
        $.each($this.tokenInput("get"), function(obj) {currentlySelectedIds.push(obj.id);});

        $.each(searchData.search_data.results, function(index, obj) {
          // only allow selection of unselected items
          if ($.inArray(obj.uri, currentlySelectedIds) === -1) {
            var json = obj;
            if (obj.hasOwnProperty("json")) {
              json = JSON.parse(obj.json);
            }
            formattedResults.push({
              name: formattedNameForJSON(json),
              id: obj.id,
              json: json
            });
          }
        });
        return formattedResults;
      };


      var addEventBindings = function() {
        $(".linker-browse-btn", $linkerWrapper).on("click", showLinkerBrowseModal);
        $(".linker-create-btn", $linkerWrapper).on("click", showLinkerCreateModal);
        $this.on("tokeninput.enter", showLinkerCreateModal);
      };


      var clearTokens = function() {
        // as tokenInput plugin won't clear a token
        // if it has an input.. remove all inputs first!
        var $tokenList = $(".token-input-list", $this.parent());
        for (var i=0; i<$this.tokenInput("get").length; i++) {
          var id_to_remove = $this.tokenInput("get")[i].id.replace(/\//g,"_");
          $("#"+id_to_remove + " :input", $tokenList).remove();
        }
        $this.tokenInput("clear");
      };


      var enableSorting = function() {
        if ($(".token-input-list", $linkerWrapper).data("sortable")) {
          $(".token-input-list", $linkerWrapper).sortable("destroy");
        }
        $(".token-input-list", $linkerWrapper).sortable({
          items: 'li.token-input-token'
        });
        $(".token-input-list", $linkerWrapper).off("sortupdate").on("sortupdate", function() {
          $this.parents("form:first").triggerHandler("form-changed");
        });
      };

      var tokensForPrepopulation = function() {
        if ($this.data("multiplicity") === "one") {
          if ($.isEmptyObject($this.data("selected"))) {
            return [];
          }
          return [{
              id: $this.data("selected").uri,
              name: formattedNameForJSON($this.data("selected")),
              json: $this.data("selected")
          }];
        } else {
          if (!$this.data("selected") || $this.data("selected").length === 0) {
            return [];
          }

          return $this.data("selected").map(function(item) {
            return {
              id: item.uri,
              name: formattedNameForJSON(item),
              json: item
            };
          });
        }
      };


      var init = function() {
        $this.tokenInput(config.url, {
          animateDropdown: false,
          preventDuplicates: true,
          allowFreeTagging: false,
          tokenLimit: (config.multiplicity==="one"? 1 :null),
          caching: false,
          onCachedResult: formatResults,
          onResult: formatResults,
          zindex: 1100,
          tokenFormatter: function(item) {
            item.name = formattedNameForJSON(item.json);
            var tokenEl = $(AS.renderTemplate("linker_selectedtoken_template", {item: item, config: config}));
            $("input[name*=resolved]", tokenEl).val(JSON.stringify(item.json));
            return tokenEl;
          },
          resultsFormatter: function(item) {
            var string = item.name;
            var $resultSpan = $("<span class='"+ item.json.jsonmodel_type + "'>");
            $resultSpan.text(string);
            $resultSpan.prepend("<span class='icon-token'></span>");
            var $resultLi = $("<li>");
            $resultLi.append($resultSpan);
            return $resultLi[0].outerHTML;
          },
          prePopulate: tokensForPrepopulation(),
          onDelete: function() {
            $this.parents("form:first").triggerHandler("form-changed");
          },
          onAdd:  function(item) {
            if (config.sortable && config.multiplicity == "many") {
              enableSorting();
            }
            $this.parents("form:first").triggerHandler("form-changed");
            $(document).triggerHandler("init.popovers");
          },
          formatQueryParam: function(q, ajax_params) {
            if ($this.tokenInput("get").length || config.exclude_ids.length) {
              var currentlySelectedIds = $.merge([], config.exclude_ids);
              $.each($this.tokenInput("get"), function(obj) {currentlySelectedIds.push(obj.id);});

              ajax_params.data["exclude[]"] = currentlySelectedIds;
            }
            if (config.types && config.types.length) {
              ajax_params.data["type"] = config.types;
            }

            return (q+"*").toLowerCase();
          }
        });

        $this.parent().addClass("multiplicity-"+config.multiplicity);

        if (config.sortable && config.multiplicity == "many") {
          enableSorting();
          $linkerWrapper.addClass("sortable");
        }

        $(document).triggerHandler("init.popovers");

        addEventBindings();
      };

      init();
    });
  };
});

$(document).ready(function() {
  $(document).ajaxComplete(function() {
    $(".linker:not(.initialised)").linker();
  });

  $(".linker:not(.initialised)").linker();

  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    $(".linker:not(.initialised)", subform).linker();
  });
});
