$(function() {

  $(document).bind("create.subrecord", function(event, object_name, defined_type, index_data, $target_subrecord_list, callback) {
    var instanceTypeEl = $(AS.renderTemplate("template_instance_type", index_data));
   instanceTypeEl.val(defined_type.value);

    if (object_name === "instance") {
      var formEl;
      if (defined_type.value === "digital_object") {
        formEl = $(AS.renderTemplate("template_instance_digital_object", index_data));
      } else {
        formEl = $(AS.renderTemplate("template_instance_container", index_data));
      }
      $("h4.subrecord-form-heading", formEl).html(defined_type.label);

      formEl.append(instanceTypeEl);

      callback(formEl, $target_subrecord_list);
    }
    return true;
  });

});
