//= require tree
//= require resources.crud
//= require dates.crud
//= require agents.crud
//= require subjects.crud
//= require deaccessions.crud
//= require subrecord.crud
//= require rights_statements.crud
//= require detect_form_changes

$(function() {

  $.fn.init_accession_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var form_changed = false;

      $this.addClass("initialised");


      var addEventBindings = function() {
        $this.bind("formchanged.aspace", function() {
          form_changed = true;
        });

        $this.bind("submit", function() {
          form_changed = false;
        });

        $(window).bind("beforeunload", function(event) {
          if (form_changed) {
            return 'Please note you have some unsaved changes.';
          }
        });
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