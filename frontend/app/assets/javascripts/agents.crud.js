//= require subrecord.crud

$(function() {

  var init_name_form = function(subform) {
    var $checkbox = $(":checkbox[name$=\"[sort_name_auto_generate]\"]", subform);
    var $sortNameField = $(":input[name$=\"[sort_name]\"]", subform);
    if ($checkbox.is(":checked")) {
      $sortNameField.attr("readonly","readonly");
      $sortNameField.closest(".control-group").hide();
    }

    $checkbox.change(function() {
      if ($checkbox.is(":checked")) {
        $sortNameField.attr("readonly","readonly");
        $sortNameField.closest(".control-group").hide();
      } else {
        $sortNameField.removeAttr("readonly");
        $sortNameField.closest(".control-group").show();
      }
    });
  };


  $(document).bind("new.subrecord, init.subrecord", function(event, object_name, subform) {
    if (object_name === "name") {
      init_name_form($(subform));
    }
  });

});
