$(function() {

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

  var initDateForm = function(subform) {
    $("label.radio", subform).click(function(event) {
      var $label = $(this);
      $(":radio", subform).removeAttr("checked");
      setTimeout(function() {
        $(":radio", $label).attr("checked", "checked");
        $.proxy(toggleDisabledFields, subform)();
      },0);
      subform.parents("form:first").triggerHandler("form-changed");
      $.proxy(toggleDisabledFields, subform)();
    });
    $("label.radio :radio:checked", subform).parents(".accordion-group:first").find(".accordion-body").removeClass("collapsed").addClass("in");
  };

  $(document).bind("new.subrecord, init.subrecord", function(event, object_name, subform) {
    if (object_name === "date") {
      initDateForm(subform);
    }
  });

});
