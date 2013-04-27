$(function() {

  $(document).bind("subrecordcreaterequest.aspace", function(event, object_name, add_button_data, index_data, $target_subrecord_list, callback) {
    if (object_name === "instance") {
      var formEl;
      if (add_button_data.instanceType === "digital-instance") {
        formEl = $(AS.renderTemplate("template_instance_digital_object", index_data));
      } else {
        formEl = $(AS.renderTemplate("template_instance_container", index_data));
      }

      callback(formEl, $target_subrecord_list);
    }
    return true;
  });

});
