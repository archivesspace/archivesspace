//= require subrecord.collapsible.js

$(function () {
  var initLangMaterialForm = function ($form) {};

  $(document).bind(
    'subrecordcreaterequest.aspace',
    function (
      event,
      object_name,
      add_button_data,
      index_data,
      $target_subrecord_list,
      callback
    ) {
      if (object_name === 'lang_material') {
        var formEl;
        if (add_button_data.langmaterialType === 'language_note') {
          formEl = $(AS.renderTemplate('template_language_notes', index_data));
        } else {
          formEl = $(AS.renderTemplate('template_language_fields', index_data));
          formEl.data('collapsed', false);
        }

        callback(formEl, $target_subrecord_list);
      }
      return true;
    }
  );

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      if (object_name === 'lang_material') {
        initLangMaterialForm($(subform));
      }
    }
  );
});
