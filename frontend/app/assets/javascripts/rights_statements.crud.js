$(function() {

  var init_rights_statements_form = function(subform) {

    // add binding for rights type select
    $("[name$='[rights_type]']", subform).change(function(event) {
      var type = $(this).val();

      var values = {};

      if ($(".rights-type-subform", subform).length) {
        values = $(".rights-type-subform", subform).serializeObject();
        $(".rights-type-subform", subform).remove();
      }

      if (type === "") {
        $(this).parents(".form-group:first").after(AS.renderTemplate("template_rights_type_nil"));
        return;
      }

      var index = $(this).parents("[data-index]:first").data("index");

      var template_data = {
        path: AS.quickTemplate($(this).parents("[data-name-path]:first").data("name-path"), {index: index}),
        id_path: AS.quickTemplate($(this).parents("[data-id-path]:first").data("id-path"), {index: index}),
        index: index
      };

      var $rights_type_subform = $(AS.renderTemplate("template_rights_type_"+type, template_data));

      $(this).parents(".form-group:first").after($rights_type_subform);

      $rights_type_subform.setValuesFromObject(values);

      $(document).triggerHandler("subrecordcreated.aspace", ["rights_type", $rights_type_subform]);
    });

  };


  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "rights_statement") {
      init_rights_statements_form($(subform));
    }
  });

});
