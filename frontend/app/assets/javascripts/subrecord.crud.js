$(function() {

  $.fn.init_subrecord_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      $this.data("form_index", $("> .subrecord-form-container .subrecord-form-fields", $this).length);


      var numberOfSubRecords = function() {
        return $(".subrecord-form-list:first li", $this).length;
      };

      var init = function() {

        $(document).bind("subrecordcreated.aspace", function(e, object_name, formel) {
          formel.triggerHandler(e);
        });

        var init_subform = function() {
          var $subform = $(this);

          if ($subform.hasClass("initialised")) {
            return;
          }

          $subform.addClass("initialised");

          var addRemoveButton = function() {
            var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
            $subform.prepend(removeBtn);
            removeBtn.on("click", function() {
              AS.confirmSubFormDelete($(this), function() {
                $subform.remove();
                // if cardinality is zero_to_one, disabled the button if there's already an entry
                if ($this.data("cardinality") === "zero_to_one") {
                  $("> .subrecord-form-heading > .btn", $this).removeAttr("disabled");
                }
                $this.parents("form:first").triggerHandler("form-changed");
                $(document).triggerHandler("subrecorddeleted.aspace", [$this]);
              });
              return false;
            });
          }

          if ($subform.closest(".subrecord-form").data("remove") != "disabled") {
            addRemoveButton();
          }

          AS.initSubRecordSorting($("ul.subrecord-form-list", $subform));

          // if cardinality is zero_to_one, disabled the button if there's already an entry
          if ($this.data("cardinality") === "zero_to_one") {
            $("> .subrecord-form-heading > .btn", $this).attr("disabled", "disabled");
          }

          $(document).triggerHandler("subrecordcreated.aspace", [$subform.data("object-name") || $this.data("object-name"), $subform]);
        };

        var addAndInitForm = function(formHtml, $target_subrecord_list) {
          var formEl = $("<li>").append(formHtml);
          formEl.attr("data-index", $this.data("form_index"));
          formEl.hide();

          $target_subrecord_list.append(formEl);

          formEl.fadeIn();

          // re-init the sortable behaviour
          AS.initSubRecordSorting($target_subrecord_list);

          $this.parents("form:first").triggerHandler("form-changed");

          $.proxy(init_subform, formEl)();

          //init any sub sub record forms
          $(".subrecord-form:not(.initialised)",formEl).init_subrecord_form();

          $(document).triggerHandler("subrecordcreated.aspace", [$this.data("object-name"), formEl]);

          $(":input:visible:first", formEl).focus();

          $this.data("form_index", $this.data("form_index")+1);
        };

        // add binding for creation of subforms
        if ($this.data("custom-action")) {
          // Support custom actions - just buttons really with some data attributes
          $("> .subrecord-form-heading > .custom-action .btn", $this).on("click", function(event) {
            event.preventDefault();

            var $target_subrecord_list = $(".subrecord-form-list:first", $(this).parents(".subrecord-form:first"));

            var index_data = {
              path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: $this.data("form_index")}),
              id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: $this.data("form_index")}),
              index: "${index}"
            };

            $(document).triggerHandler("subrecordcreaterequest.aspace", [$this.data("object-name"), $(this).data(), index_data, $target_subrecord_list, addAndInitForm]);
          });
        } else {

          $("> .subrecord-form-heading > .btn", $this).on("click", function() {

            var $target_subrecord_list = $(".subrecord-form-list:first", $(this).parents(".subrecord-form:first"));

            var index_data = {
              path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: $this.data("form_index")}),
              id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: $this.data("form_index")}),
              index: "${index}"
            };

            var formEl = $(AS.renderTemplate($this.data("template"), index_data));
            addAndInitForm(formEl, $target_subrecord_list);
          });
        };

        var $list = $("ul.subrecord-form-list:first", $this);

        AS.initAddAsYouGoActions($this, $list);
        AS.initSubRecordSorting($list);

        // init any existing subforms
        $("> .subrecord-form-container .subrecord-form-list > .subrecord-form-wrapper", $this).each(init_subform);

      }

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $(".subrecord-form[data-subrecord-form]:not(.initialised)").init_subrecord_form();
    });

    $(".subrecord-form[data-subrecord-form]:not(.initialised)").init_subrecord_form();

    $(document).bind("monkeypatch.subrecord", function(event, subform) {
      $(".subrecord-form[data-subrecord-form]", subform).init_subrecord_form();
    });
  });

});