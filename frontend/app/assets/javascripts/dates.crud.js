$(function() {
  var $this = $(".content-pane form");


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

    $("#date_type .accordion-group label", dateFormEl).click(function(event) {
      $(":radio", $(this).parents(".control-group:first")).removeAttr("checked");
      $(":radio", this).attr("checked", "checked");
      $.proxy(toggle_disabled_fields, $(this).parents("#date_type"))();
    });


    $("#date_type", dateFormEl).each(toggle_disabled_fields);

  };


  $this.on("click", "#dates > h3 > .btn", function() {
    var forms = $(".subform.date-fields", $this).length;
    var dateFormEl = $(AS.renderTemplate("date_form_template", {index: forms}));
    $("#dates_container", $this).append(dateFormEl);
    $(".alert", $("#dates_container", $this)).hide();
    $this.triggerHandler("form-changed");
    $.proxy(init_date_form, dateFormEl)();
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
    $("#date_type label.radio :radio:checked", this).parents(".accordion-group:first").find(".accordion-body").removeClass("collapsed").addClass("in");
  });

});