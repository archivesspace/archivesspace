//= require dates.crud

$(function() {

  $.fn.init_accession_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");


      var addEventBindings = function() {
        $this.on("click", "#extent > h3 > .btn", function() {
          var extent_forms = $(".subform.extent-fields", $this).length;
          $("#extents_container", $this).append(AS.renderTemplate("extent_form_template", {index: extent_forms}));
          $this.triggerHandler("form-changed");
        });


        $this.on("click", "#extent .subform-remove", function() {
          $(this).parents(".subform:first").remove();
          $this.triggerHandler("form-changed");
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