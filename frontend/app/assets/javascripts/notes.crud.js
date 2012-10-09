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
        event.preventDefault();
        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        var $subform = $(AS.renderTemplate(selected.val()+"_form_template", {
          path: "foo",
          index: index,
          type: selected.text()
        }));

        $(".notes-container", $this).append($subform);

        // add the remove button
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            $subform.remove();
            $this.parents("form:first").triggerHandler("form-changed");
          });
        });

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