$(function() {
  var $this = $(".content-pane form");

  var form_index = $(".subform.date-fields", $this).length;

  var toggle_disabled_fields = function() {
    $("label.radio :radio", this).each(function() {
      var $group = $(this).parents(".accordion-group:first");
      if ($(this).is(":checked")) {
        $(".accordion-body :input", $group).removeAttr("disabled");
      } else {
        $(".accordion-body :input", $group).attr("disabled","disabled");
      }
    });
  };


  var init_date_form = function() {
    var dateFormEl = $(this);
    
    if (dateFormEl.hasClass("initialised")) {
      return;
    }

    dateFormEl.addClass("initialised");

    $(".date-type-accordion .accordion-group label", dateFormEl).click(function(event) {
      $(":radio", $(this).parents(".date-type-accordion:first")).removeAttr("checked");
      $(":radio", this).attr("checked", "checked");
      $.proxy(toggle_disabled_fields, $(this).parents(".date-type-accordion:first"))();
    });


    $(".date-type-accordion", dateFormEl).each(toggle_disabled_fields);

  };


  $this.on("click", "#dates > h3 > .btn", function() {
    var dateFormEl = $(AS.renderTemplate("date_form_template", {index: form_index++}));
    $("#dates_container", $this).append(dateFormEl);
    $(".alert", $("#dates_container", $this)).hide();
    $this.triggerHandler("form-changed");
    $.proxy(init_date_form, dateFormEl)();
    $(":input:visible:first", dateFormEl).focus();
  });


  $this.on("click", "#dates .subform-remove", function() {
    $(this).parents(".subform:first").remove();
    $this.triggerHandler("form-changed");
    if ($("#dates_container .date-form", $this).length === 0) {
      $(".alert", $("#dates_container", $this)).show();
    }
  });


  $("#dates .date-fields", $this).each(function() {
    $.proxy(init_date_form, this)();
    $(".date-type-accordion label.radio :radio:checked", this).parents(".accordion-group:first").find(".accordion-body").removeClass("collapsed").addClass("in");
  });

});