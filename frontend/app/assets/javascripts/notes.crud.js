$(function() {

  $.fn.init_notes_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-wrapper", $this).length;

      $(".add-note-for-type-btn", $this).click(function(event) {
        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        $(".notes-container", $this).append(AS.renderTemplate(selected.val()+"_form_template", {
          path: "foo",
          index: index,
          type: selected.text()
        }));
        index++;
      });

    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#notes:not(.initialised)").init_notes_form();
    });

    $("#notes:not(.initialised)").init_notes_form();
  });

});