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
        format: $this.data("format"),
        format_property: $this.data("format_property"),
        controller: $this.data("controller"),
        path: $this.data("path"),
        name: $this.data("name"),
        multiplicity: $this.data("multiplicity") || "many",
        label: $this.data("label"),
        label_plural: $this.data("label_plural"),
        modal_id: "linkerModalFor_"+$this.data("class")
      };

      var renderItemsInModal = function() {
        var currentlySelectedIds = $this.tokenInput("get").map(function(obj) {return obj.id;});
        $.ajax({
          url: config.url,
          type: "GET",
          dataType: "json",
          success: function(json) {
            $("#"+config.modal_id).find(".linker-list").html(AS.renderTemplate("linker_browse_template", {items: json, config: config, selected: currentlySelectedIds}));
          }
        });
      };


      var formattedNameForJSON = function(json) {
        if (config.format) {
          return AS.quickTemplate(config.format, json);
        } else if (config.format_property) {
          return json[config.format_property];
        }
        return "ERROR: no format for name (formattedNameForJSON)"
      };

      var renderCreateFormForObject = function() {
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
          url: APP_PATH+config.controller+"/new?inline=true",
          success: initCreateForm
        });
        $("#createAndLinkButton", $modal).click(function() {
          $("form", $modal).triggerHandler("submit");
        });
      };


      var showLinkerCreateModal = function() {
        AS.openCustomModal(config.modal_id, "Create "+ config.label, AS.renderTemplate("linker_createmodal_template", config));
        renderCreateFormForObject();
      };


      var addSelected = function() {
        selectedItems  = [];
        $(".token-input-delete-token", $linkerWrapper).each(function() {
          $(this).triggerHandler("click");
        });
        $(".linker-list :input:checked", "#"+config.modal_id).each(function() {
          var item = $(this).data("object");
          $this.tokenInput("add", {
            id: item.uri,
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
      };


      var formatResults = function(results) {
        var formattedResults = [];
        var currentlySelectedIds = $this.tokenInput("get").map(function(obj) {return obj.id;});
        $.each(results, function(index, obj) {
          // only allow selection of unselected items
          if ($.inArray(obj.uri, currentlySelectedIds) === -1) {
            formattedResults.push({
              name: formattedNameForJSON(obj),
              id: obj.uri,
              json: obj
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
          if ($this.data("selected").length === 0) {
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
          onCachedResult: formatResults,
          onResult: formatResults,
          tokenFormatter: function(item) {
            var tokenEl = $(AS.renderTemplate("linker_selectedtoken_template", {item: item, config: config}));
            $("input[name*=resolved]", tokenEl).val(JSON.stringify(item.json));
            return tokenEl;
          },
          prePopulate: tokensForPrepopulation(),
          onDelete: function() {
            $this.parents("form:first").triggerHandler("form-changed");
          },
          onAdd:  function(item) {
            $this.parents("form:first").triggerHandler("form-changed");
          }
        });

        $this.parent().addClass("multiplicity-"+config.multiplicity);

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

  $(document).bind("new.subrecord", function(event, object_name, subform) {
    $(".linker:not(.initialised)", subform).linker();
  });
});