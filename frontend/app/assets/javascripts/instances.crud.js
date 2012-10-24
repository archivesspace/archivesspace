$(function() {

  var renderContainer = function() {
    if ($(".container-form-wrapper:visible", this).length) {
      // container already rendered
      return;
    }

    $(".instance-container-or-digital-object > div", this).hide();
    $(".instance-container-or-digital-object .instance-type-with-container", this).show();
    $(".instance-container-or-digital-object :input:hidden", this).attr("disabled", "disabled");
    $(".instance-container-or-digital-object .instance-type-with-container :input", this).removeAttr("disabled");
  };

  var renderDigitalObject = function() {
    $(".instance-container-or-digital-object > div", this).hide();
    $(".instance-container-or-digital-object .instance-type-digital-object", this).show();
    $(".instance-container-or-digital-object :input:hidden", this).attr("disabled", "disabled");
    $(".instance-container-or-digital-object  .instance-type-digital-object :input", this).removeAttr("disabled");
  };

  var renderDigitalObjectLink = function() {
    $(".instance-container-or-digital-object > div", this).hide();
    $(".instance-container-or-digital-object .instance-type-digital-object-link", this).show();
    $(".instance-container-or-digital-object :input:hidden", this).attr("disabled", "disabled");
    $(".instance-container-or-digital-object  .instance-type-digital-object-link :input", this).removeAttr("disabled");
  };

  var renderNilValue =function() {
    $(".instance-container-or-digital-object > div", this).hide();
    $(".instance-container-or-digital-object .instance-type-nil", this).show();
    $(".instance-container-or-digital-object :input", this).attr("disabled", "disabled");
  }

  var initInstance = function(subform) {
    if ($(this).val() === "digital_object") {
      $.proxy(renderDigitalObject, subform)();
    } else if ($(this).val() === "digital_object_link") {
      $.proxy(renderDigitalObjectLink, subform)();
    } else if ($(this).val() === "") {
      $.proxy(renderNilValue, subform)();
    } else {
      $.proxy(renderContainer, subform)();
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
