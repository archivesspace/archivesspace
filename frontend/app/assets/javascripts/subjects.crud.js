//= require terms.crud
//= require subrecord.crud

$(function() {

  $.fn.init_subject_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      // initialise the term form
      $(document).triggerHandler("subrecordcreated.aspace", ["term", $("#terms", $this)]);
    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#new_subject:not(.initialised)").init_subject_form();
    });

    $("#new_subject:not(.initialised)").init_subject_form();
  });

});