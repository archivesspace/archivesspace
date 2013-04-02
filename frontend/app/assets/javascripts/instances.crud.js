$(function() {

  $(document).bind("create.subrecord", function(event, object_name, defined_type, index_data, $target_subrecord_list, callback) {
    if (object_name === "instance") {
      var formEl;
      if (defined_type.value === "digital_object") {
        formEl = $(AS.renderTemplate("template_instance_digital_object", index_data));
      } else {
        formEl = $(AS.renderTemplate("template_instance_container", index_data));
      }
      $("h4.subrecord-form-heading", formEl).html(defined_type.label);

      // Set the instance type to be the selected value
      $('[id$="_instance_type_"]', formEl).val(defined_type.value);

      callback(formEl, $target_subrecord_list);
    }
    return true;
  });

});
