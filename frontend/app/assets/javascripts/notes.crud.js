$(function() {

  $.fn.init_notes_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-wrapper", $this).length;

      var initBibliographyNote = function($subform) {
        $(".add-bibliography-item-btn", $subform).click(function() {

          var $subsubform = $(AS.renderTemplate("note_bibliography_item_form_template", {
            path: "foo",
            index: index
          }));

          $(".subrecord-form-container", $subform).append($subsubform);

          initRemoveActionForSubRecord($subsubform)
        });
      };


      var initRemoveActionForSubRecord = function($subform) {
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            $subform.remove();
            $this.parents("form:first").triggerHandler("form-changed");
          });
        });
      };


      var initMultipartNote = function($subform) {
        $(".add-sub-note-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));
          var $subsubform = $(AS.renderTemplate(selected.text()+"_form_template", {
            path: "foo",
            index: index,
            type: selected.text()
          }));

          $(".subrecord-form-container", $subform).append($subsubform);

          initRemoveActionForSubRecord($(".subrecord-form-heading", $subsubform));

          if (selected.text() === "note_bibliography") {
            initBibliographyNote($subsubform);
          }
        });
      };


      var initTopLevelNote = function(event) {
        event.preventDefault();

        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        var $subform = $(AS.renderTemplate(selected.val()+"_form_template", {
          path: "foo",
          index: index,
          type: selected.text()
        }));

        $(".notes-container", $this).append($subform);

        initRemoveActionForSubRecord($subform);

        if (selected.val() === "note_multipart") {
          initMultipartNote($subform);
        }

        index++;
      };

      $(".add-note-for-type-btn", $this).click(initTopLevelNote);

    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#notes:not(.initialised)").init_notes_form();
    });

    $("#notes:not(.initialised)").init_notes_form();
  });

});