$(function() {

  var initInstance = function(subform) {
    var $target = $(".instance-container-or-digital-object", subform);

    var index_data = {
      path: AS.quickTemplate($target.closest(".subrecord-form-list").data("name-path"), {index: $target.closest("li").data("index")}),
      id_path: AS.quickTemplate($target.closest(".subrecord-form-list").data("id-path"), {index: $target.closest("li").data("index")}),
      index: "${index}"
    };

    if ($(this).val() === "digital_object") {
      $target.html(AS.renderTemplate("template_instance_digital_object", index_data));
    } else if ($(this).val() === "") {
      $target.html(AS.renderTemplate("template_instance_empty"));
    } else if ($(".container-fields", $target).length === 0) {  
      index_data.path += "[container]" 
      index_data.id_path += "_container_" 
      $target.html(AS.renderTemplate("template_container", index_data));
      $(document).triggerHandler("monkeypatch.subrecord", [$target]);
    }
  }

  $(document).bind("new.subrecord, init.subrecord", function(event, object_name, subform) {
    if (object_name === "instance") {
      $("[name^='resource[instances]['][name$='][instance_type]']", subform).change(function(event) {
        $.proxy(initInstance, this)(subform);
      }).triggerHandler("change");
      if (event.type === "init") {
        $.proxy(initInstance, $("[name^='resource[instances]['][name$='][instance_type]']", subform))(subform);
      }
    }
    return true;
  });

});
