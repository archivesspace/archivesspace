$(function() {

  var initDateForm = function(subform) {

    $("[name$='[date_type]']", subform).change(function(event) {
      var type = $(this).val();

      var values = {};

      if ($(".date-type-subform", subform).length) {
        values = $(".date-type-subform", subform).serializeObject();
        $(".date-type-subform", subform).remove();
      }

      if (type === "") {
        $(this).parents(".form-group:first").after(AS.renderTemplate("template_date_type_nil"));
        return;
      }

      var index = $(this).parents("[data-index]:first").data("index");

      var template_data = {
        path: AS.quickTemplate($(this).parents("[data-name-path]:first").data("name-path"), {index: index}),
        id_path: AS.quickTemplate($(this).parents("[data-id-path]:first").data("id-path"), {index: index}),
        index: index
      };

      var $date_type_subform = $(AS.renderTemplate("template_date_type_"+type, template_data));

      $(this).parents(".form-group:first").after($date_type_subform);

      $date_type_subform.setValuesFromObject(values);

      $(document).triggerHandler("subrecordcreated.aspace", ["date_type", $date_type_subform]);
    });

  };

  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "date" || object_name === "dates_of_existence" || object_name == "use_date") {
      initDateForm($(subform));
    }
  });

});
