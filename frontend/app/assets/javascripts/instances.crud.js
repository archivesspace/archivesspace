//= require subrecord.collapsible.js
//= require representativemembers.js
//= require space_calculator.js

$(function() {

  var initInstanceForm = function($form) {
    // only enable collapsible for non-digital instances
    // as digital instances are small enough
    if ($(":input[id*='_instance_type_']", $form).val() != "digital_object") {
      AS.initSubRecordCollapsible($form.find(".subrecord-form-fields:first"), function() {
        var instance_data = {
          instance_type: $(":input[id*='instance_type']:first :selected", $form).text(),
          type_1: $(":input[id*='type_1']:first :selected", $form).text(),
          indicator_1: $(":input[id*='indicator_1']:first", $form).val(),
          type_2: $(":input[id*='type_2']:first :selected", $form).text(),
          indicator_2: $(":input[id*='indicator_2']:first", $form).val()
        };
        return AS.renderTemplate("template_instance_summary", instance_data);
      });
    }
  };

  $(document).bind("subrecordcreaterequest.aspace", function(event, object_name, add_button_data, index_data, $target_subrecord_list, callback) {
    if (object_name === "instance") {
      var formEl;
      if (add_button_data.instanceType === "digital-instance") {
        formEl = $(AS.renderTemplate("template_instance_digital_object", index_data));
      } else {
        formEl = $(AS.renderTemplate("template_instance_container", index_data));
        formEl.data("collapsed", false);
      }

      callback(formEl, $target_subrecord_list);
    }
    return true;
  });

  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "instance") {
      initInstanceForm($(subform));
    }
  });

});
