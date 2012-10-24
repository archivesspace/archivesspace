(function() {
  $(document).bind("new.subrecord, init.subrecord", function(event, object_name, subform) {
    if (object_name === "deaccession") {
      $(document).triggerHandler("init.subrecord", ["date", $("#deaccession_date .subrecord-form-fields:first", subform)]);
    }
  });
})();
