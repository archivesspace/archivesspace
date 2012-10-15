$(function() {

  $.fn.init_notes_form = function() {

    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-fields", $this).length;

      var initialisers = {}

      var initNoteType = function($subform, template_name, is_subrecord, button_class) {

        $((button_class || ".add-item-btn"), $subform).click(function() {
          event.preventDefault();

          if (typeof(template_name) === 'function') {
            template_name = template_name($(this));
          }

          var $target_subrecord_list = $(this).siblings(".subrecord-form-list:first").add(".subrecord-form-list:first", $subform).first();

          var $subsubform = $(AS.renderTemplate(template_name, {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $target_subrecord_list.append($subsubform);

          initNoteForm($subsubform);

          if (is_subrecord) {
            $(document).triggerHandler("subrecord.new", ["note", $subsubform]);
          }

          $this.parents("form:first").triggerHandler("form-changed");

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      initialisers.note_bibliography = function($subform) {
        initNoteType($subform, "template_bib_item");
      };


      var dropdownFocusFix = function(form) {
        $('.dropdown-menu.subrecord-selector li', form).click(function(e) {
          if (!$(e.target).hasClass('btn')) {
            // Don't hide the dropdown unless what we clicked on was the "Add" button itself.
            e.stopPropagation();
          }
        });
      }

      dropdownFocusFix();


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


      initialisers.note_index = function($subform) {
        initNoteType($subform, "template_index_item");
      };


      initialisers.note_chronology = function($subform) {
        initNoteType($subform, "template_chronology_item", true);
      };


      initialisers.note_definedlist = function($subform) {
        initNoteType($subform, "template_definedlist_item");
      };


      initialisers.note_orderedlist = function($subform) {
        initNoteType($subform, "template_orderedlist_item");
      };


      initialisers.chronology_item = function($subform) {
        initNoteType($subform, "template_orderedlist_item", false, '.add-event-btn');
      };

      initialisers.note_multipart = function($subform) {

        var template_name = function (self) {
          var selected = $("option:selected", self.parents(".dropdown-menu"));
          return "template_"+selected.val();
        }

        initNoteType($subform, template_name, true, '.add-sub-note-btn');
      };


      var initNoteForm = function($noteform) {
        if ($noteform.hasClass("initialised")) {
          return;
        }
        $noteform.addClass("initialised")

        initRemoveActionForSubRecord($noteform);

        dropdownFocusFix($noteform);

        var note_type = $noteform.data("type");
        if (initialisers[note_type]) {
          initialisers[note_type]($noteform);
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

        $(document).triggerHandler("subrecord.new", ["note", $subform]);

        $(":input:visible:first", $subform).focus();

        $this.parents("form:first").triggerHandler("form-changed");

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
