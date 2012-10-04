$(function() {

  $.fn.init_subrecord_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      $this.data("form_index", $("> .subrecord-form-container .subrecord-form-wrapper", $this).length);


      var init_subform = function() {
        var $subform = $(this);

        if ($("> .subrecord-form-fields", $subform).data("allow-removal") === true) {
          var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
          $subform.prepend(removeBtn);
          removeBtn.on("click", function() {
            AS.confirmSubFormDelete($(this), function() {
              $subform.remove();
              $this.parents("form:first").triggerHandler("form-changed");
              if ($("> .subrecord-form-container .subrecord-form-wrapper", $this).length === 0) {
                $("> .subrecord-form-container > .alert", $this).show();
              }
            });
          });

          // init any sub sub records!
          $(".subrecord-form:not(.initialised)", $subform).init_subrecord_form();
        }

        $(document).triggerHandler("subrecord.new", [$this.data("object-name"), $subform]);
      };


      var init = function() {
        // add binding for creation of subforms
        $("> h3 > .btn", $this).on("click", function() {

          var index_data = {
            "index": $this.data("form_index"),
            "sub_index" : "${index}"
          };

          var formEl = $(AS.renderTemplate($this.data("template-id"), index_data));
          formEl.hide();

          // re-enable form elements if a nested sub form template was used
          if ($("#"+ $this.data("template-id")).hasClass("nested-template")) {
            $(":input", formEl).removeAttr("disabled");
          }

          $("> .subrecord-form-container", $this).append(formEl);
          formEl.fadeIn();
          $("> .subrecord-form-container > .alert", $this).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, formEl)();
          $(":input:visible:first", formEl).focus();
          $this.data("form_index", $this.data("form_index")+1);
        });

        // if a nested subrecord, esnure any sub record template :inputs are disabled
        if ($("#"+ $this.data("template-id")).hasClass("nested-template")) {
          $(":input", $("#"+ $this.data("template-id"))).attr("disabled","disabled");
        }

        // init any existing subforms
        $("> .subrecord-form-container > .subrecord-form-wrapper", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $(".subrecord-form:not(.initialised)").init_subrecord_form();
    });

    $(".subrecord-form:not(.initialised)").init_subrecord_form();
  });

});