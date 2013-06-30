//= require terms.crud
//= require subrecord.crud
//= require form
//= require merge_dropdown

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
    $(document).bind("loadedrecordform.aspace", function(event, $container) {
      $("#new_subject:not(.initialised)", $container).init_subject_form();
    });

    $("#new_subject:not(.initialised)").init_subject_form();
  });

});
