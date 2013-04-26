(function() {
  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "deaccession") {
      $(document).triggerHandler("subrecordcreated.aspace", ["date", $("#deaccession_date .subrecord-form-fields:first", subform)]);
    }
  });
})();
