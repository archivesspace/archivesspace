//= require agents.crud
//= require dates.crud
//= require subrecord.crud

$(document).ready(function() {
  $(document).triggerHandler("init.subrecord", ["date", $("#event_date .subrecord-form-fields")]);
});