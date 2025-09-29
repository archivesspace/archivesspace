//= require tree
//= require subrecord.crud
//= require form
//= require slug

// We need to trigger the events to make sure the form fields are initialized.
$(document).ready(function () {
  if ($('#form_classification_term').length) {
    $(document).triggerHandler('loadedrecordform.aspace', [
      $('#form_classification_term'),
    ]);
    $(document).triggerHandler('loadedrecordsubforms.aspace', [
      $('#form_classification_term'),
    ]);
  }
});
