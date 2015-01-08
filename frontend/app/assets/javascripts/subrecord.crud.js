//= require form

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

        // Proxy the event onto the subrecord's form
        // This is used by utils.js to initialise the asYouGo
        // behaviour (quick addition of subrecords)
        $(document).on("subrecordcreated.aspace", function(e, object_name, formel) {
          formel.triggerHandler(e);
        });

        var init_subform = function() {
          var $subform = $(this);

          if ($subform.hasClass("initialised")) {
            return;
          }

          $subform.addClass("initialised");

          var addRemoveButton = function() {
            var removeBtn = $("<a href='javascript:void(0)' class='btn btn-default btn-xs pull-right subrecord-form-remove'><span class='glyphicon glyphicon-remove'></span></a>");
            $subform.prepend(removeBtn);
            removeBtn.on("click", function() {
              AS.confirmSubFormDelete($(this), function() {
                $subform.remove();
                // if cardinality is zero_to_one, disabled the button if there's already an entry
                if ($this.data("cardinality") === "zero_to_one") {
                  $("> .subrecord-form-heading > .btn", $this).removeAttr("disabled");
                }
                $this.parents("form:first").triggerHandler("formchanged.aspace");
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

          $this.parents("form:first").triggerHandler("formchanged.aspace");

          $.proxy(init_subform, formEl)();

          //init any sub sub record forms
          $(".subrecord-form:not(.initialised)", formEl).init_subrecord_form();

          $(":input:visible:first", formEl).focus();

          $this.data("form_index", $this.data("form_index")+1);
        };

        // add binding for creation of subforms
        if ($this.data("custom-action")) {
          // Support custom actions - just buttons really with some data attributes
          $($this).on("click", "> .subrecord-form-heading > .custom-action .btn:not(.show-all)", function(event) {
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

          $($this).on("click", "> .subrecord-form-heading > .btn:not(.show-all)", function(event) {
            event.preventDefault();

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
         
        var subformsExisting = $("> .subrecord-form-container .subrecord-form-list > .subrecord-form-wrapper:not(.initialised)", $this) 
        
        if (subformsExisting.length > 4 ) { 
          $("> .subrecord-form-heading > .btn.show-all", $this).show(); 
          $($this).on("click", "> .subrecord-form-heading > .btn.show-all", function(event) {
            this.disabled = true;  
            
            event.preventDefault(); 
            subformsExisting.show(); 
            subformsExisting.each(init_subform);
            $("a.has-label.show-all", $this).hide();
          });
         
          if ($this.data("custom-action") === true ) {
            subformsExisting.each(init_subform);
          } else {  
            
            subformsExisting.slice(0,4).each(init_subform);
            subformsExisting.slice(5).hide();
          } 
        }  
          $("> .subrecord-form-container .subrecord-form-list > .subrecord-form-wrapper", $this).each(init_subform);

      }

      init();
    })
  };


  $(document).ready(function() {
    $(document).bind("loadedrecordform.aspace", function(event, $container) {
      $(".subrecord-form[data-subrecord-form]:not(.initialised)", $container).init_subrecord_form();
    });

    $(".subrecord-form[data-subrecord-form]:not(.initialised)").init_subrecord_form();

    $(document).on("subrecordmonkeypatch.aspace", function(event, subform) {
      $(".subrecord-form[data-subrecord-form]", subform).init_subrecord_form();
    });
  });

});
