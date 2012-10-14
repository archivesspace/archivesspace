$(function() {

  $.fn.init_notes_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-fields", $this).length;

      var initBibliographyNote = function($subform) {

        $(".add-item-btn", $subform).click(function() {
          event.preventDefault();

          var $target_subrecord_list = $(this).siblings(".subrecord-form-list:first");

          var $subsubform = $(AS.renderTemplate("template_bib_item", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initRemoveActionForSubRecord($subsubform)

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initRemoveActionForSubRecord = function($subform) {
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            var parentContainer = $subform.parents(".subrecord-form-container:first");
            $subform.remove();
            $this.parents("form:first").triggerHandler("form-changed");
          });
        });
      };


      var initIndexNote = function($subform) {

        $(".add-item-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));

          var $target_subrecord_list = $(".subrecord-form-list:first", $subform);

          var $subsubform = $(AS.renderTemplate("template_index_item", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initNoteForm($subsubform);

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initChronologyNote = function($subform) {

        $(".add-item-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));

          var $target_subrecord_list = $(".subrecord-form-list:first", $subform);

          var $subsubform = $(AS.renderTemplate("template_chronology_item", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initNoteForm($subsubform);

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initDefinedListNote = function($subform) {

        $(".add-item-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));

          var $target_subrecord_list = $(".subrecord-form-list:first", $subform);

          var $subsubform = $(AS.renderTemplate("template_definedlist_item", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initNoteForm($subsubform);

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initOrderedListNote = function($subform) {

        $(".add-item-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));

          var $target_subrecord_list = $(this).siblings(".subrecord-form-list:first");

          var $subsubform = $(AS.renderTemplate("template_orderedlist_item", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initRemoveActionForSubRecord($subsubform);

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initChronologyNoteItem = function($subform) {

        $(".add-event-btn", $subform).click(function() {
          event.preventDefault();

          var $target_subrecord_list = $(this).siblings(".subrecord-form-list:first");

          var $subsubform = $(AS.renderTemplate("template_chronology_item_event", {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initRemoveActionForSubRecord($subsubform);

          index++;
        });
      };

      var initMultipartNote = function($subform) {

        $(".add-sub-note-btn", $subform).click(function() {
          event.preventDefault();

          var selected = $("option:selected", $(this).parents(".dropdown-menu"));

          var $target_subrecord_list = $(".subrecord-form-list:first", $subform);

          var $subsubform = $(AS.renderTemplate("template_"+selected.text(), {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initNoteForm($subsubform);

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      var initNoteForm = function($noteform) {
        if ($noteform.hasClass("initialised")) {
          return;
        }
        $noteform.addClass("initialised")

        initRemoveActionForSubRecord($noteform);

        // init the sub note forms
        if ($noteform.data("type") === "note_multipart") {
          initMultipartNote($noteform);
        } else if ($noteform.data("type") === "note_singlepart") {
          // nothing to do ... yet!
        } else if ($noteform.data("type") === "note_bibliography") {
          initBibliographyNote($noteform);
        } else if ($noteform.data("type") === "note_chronology") {
          initChronologyNote($noteform);
        } else if ($noteform.data("type") === "chronology_item") {
          initChronologyNoteItem($noteform);
        } else if ($noteform.data("type") === "note_index") {
          initIndexNote($noteform);
        } else if ($noteform.data("type") === "index_item") {
          // nothing to do! ... yet.
        } else if ($noteform.data("type") === "note_definedlist") {
          initDefinedListNote($noteform);
        } else if ($noteform.data("type") === "definedlist_item") {
          // nothing to do!
        } else if ($noteform.data("type") === "note_orderedlist") {
          initOrderedListNote($noteform);
        } else {
           console.error("ERROR Note type note supported: " + $noteform.data("type"));
        }
      };

      var createTopLevelNote = function(event) {
        event.preventDefault();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);

        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        var $subform = $(AS.renderTemplate("template_"+selected.val(), {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
          index: "${index}"
        }));

        // set the note type
        $(".note-type", $subform).val(selected.text());

        $target_subrecord_list.append($subform);

        initNoteForm($subform)

        $(":input:visible:first", $subform).focus();

        index++;
      };

      $(".add-note-for-type-btn", $this).click(createTopLevelNote);

      // initialising forms
      if ($(".subrecord-form-list > .subrecord-form-fields", $this).length) {
        $(".subrecord-form-list > .subrecord-form-fields", $this).each(function() {
          initNoteForm($(this));
        });
        $(".subrecord-form-inline", $this).each(function() {
          initRemoveActionForSubRecord($(this));
        });
      }
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#notes.subrecord-form:not(.initialised)").init_notes_form();
    });

    $("#notes.subrecord-form:not(.initialised)").init_notes_form();
  });

});