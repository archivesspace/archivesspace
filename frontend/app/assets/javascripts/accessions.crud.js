//= require dates.crud
//= require extent.crud
//= require external_documents.crud

$(function() {

  $.fn.init_accession_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");


      var addEventBindings = function() {

      };

      addEventBindings();
    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#accession_form:not(.initialised)").init_accession_form();
    });

    $("#accession_form:not(.initialised)").init_accession_form();
  });

});