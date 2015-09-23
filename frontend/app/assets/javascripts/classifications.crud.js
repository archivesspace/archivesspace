//= require tree
//= require subrecord.crud
//= require form

// We need to trigger the events to make sure the form fields are initialized. 
$(document).ready(function() {
  if ($("#form_classification").length) {
    $(document).triggerHandler("loadedrecordform.aspace", [$("#form_classification")] ); 
    $(document).triggerHandler("loadedrecordsubforms.aspace", [$("#form_classification")] ); 
  }
});
