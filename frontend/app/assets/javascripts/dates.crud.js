$(function() {
  
  $.fn.init_date_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var form_index = $(".subform.date-fields", $this).length;


      var init_subform = function() {
        var $subform = $(this);

        $("label.radio", $subform).click(function(event) {
          $(":radio", $subform).removeAttr("checked");
          $(":radio", this).attr("checked", "checked");
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(toggleDisabledFields, $subform)();
        });

        $(".subform-remove", $subform).on("click", function() {
          $subform.remove();
          $this.parents("form:first").triggerHandler("form-changed");
          if ($(".subform.date-fields", $this).length === 0) {
            $(".alert", $("#dates_container", $this)).show();
          }
        });

        $("label.radio :radio:checked", $subform).parents(".accordion-group:first").find(".accordion-body").removeClass("collapsed").addClass("in");
        $.proxy(toggleDisabledFields, $subform)();
      };


      var toggleDisabledFields = function() {
        $("label.radio :radio", this).each(function() {
          var $group = $(this).parents(".accordion-group:first");
          if ($(this).is(":checked")) {
            $(".accordion-body :input", $group).removeAttr("disabled");
          } else {
            $(".accordion-body :input", $group).attr("disabled","disabled");
          }
        });
      };


      var init = function() {    
        // add binding for creation of subforms
        $("h3 > .btn", $this).on("click", function() {
          var dateFormEl = $(AS.renderTemplate("date_form_template", {index: form_index++}));
          $("#dates_container", $this).append(dateFormEl);
          $(".alert", $("#dates_container", $this)).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, dateFormEl)();
          $(":input:visible:first", dateFormEl).focus();
        });

        // init any existing subforms
        $(".subform.date-fields", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#dates:not(.initialised)").init_date_form();
    });

    $("#dates:not(.initialised)").init_date_form();
  });

});