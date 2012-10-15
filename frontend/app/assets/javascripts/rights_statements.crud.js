$(function() {

  $.fn.init_rights_statements_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var form_index = $(".subform.rights-statement-fields", $this).length;


      var init_subform = function() {
        var $subform = $(this);

        $(".subform-remove", $subform).on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            $subform.remove();
            $this.parents("form:first").triggerHandler("form-changed");
            if ($(".subform.rights-statement-fields", $this).length === 0) {
              $(".alert", $this).show();
            }
          });
        });

        $(document).triggerHandler("new.subrecord", ["note", $subform]);
      };


      var init = function() {
        // add binding for creation of subforms
        $("h3 > .btn", $this).on("click", function() {
          var formEl = $(AS.renderTemplate("rights_statement_form_template", {index: form_index++}));
          formEl.hide();
          $("#rights_statements_container", $this).append(formEl);
          formEl.fadeIn();
          $(".alert", $this).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, formEl)();
          $(":input:visible:first", formEl).focus();
        });

        // init any existing subforms
        $(document).bind("init.subrecord", function(event, object_name, subform) {
          $.proxy(init_subform, subform)();
        });
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#rights_statements:not(.initialised)").init_rights_statements_form();
    });

    $("#rights_statements:not(.initialised)").init_rights_statements_form();
  });

});
