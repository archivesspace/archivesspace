//= require mixed_content.js

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

      var initNoteType = function($subform, template_name, is_subrecord, button_class, init_callback) {

        $((button_class || ".add-item-btn"), $subform).click(function(event) {
          event.preventDefault();

          var template = template_name;

          if (typeof(template_name) === 'function') {
            template = template_name($(this));
          }


          var context = $(this).parent().hasClass("controls") ? $(this).parent() : $(this).closest(".subrecord-form");
          var $target_subrecord_list = $(".subrecord-form-list:first", context);

          var $subsubform = $(AS.renderTemplate(template, {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
            index: "${index}"
          }));

          $subsubform = $("<li>").data("type", $subsubform.data("type")).append($subsubform);
          $subsubform.attr("data-index", index);
          $target_subrecord_list.append($subsubform);

          AS.initSubRecordSorting($target_subrecord_list);

          if (init_callback) {
            init_callback($subsubform)
          } else {
            initNoteForm($subsubform);
          }

          if (is_subrecord) {
            $(document).triggerHandler("subrecordcreated.aspace", ["note", $subsubform]);
          }

          $this.parents("form:first").triggerHandler("form-changed");

          $(":input:visible:first", $subsubform).focus();

          index++;
        });
      };


      initialisers.note_bibliography = function($subform) {
        initNoteType($subform, "template_bib_item");
      };

      initialisers.note_outline = function($subform) {
        initNoteType($subform, "template_note_outline_level", true, '.add-level-btn');
      };

      initialisers.note_outline_level = function($subform) {
        initNoteType($subform, "template_note_outline_string", true, '.add-sub-item-btn');
        initNoteType($subform, "template_note_outline_level", true, '.add-sub-level-btn');
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


      var initContentList = function($subform) {
        if (!$subform) {
          $subform = $(document);
        }

        var contentList = $('.content-list', $subform);

        if (contentList.length > 0) {
          initNoteType(contentList, "template_content_item", true, '.add-content-item-btn');
        }
      }


      var initRemoveActionForSubRecord = function($subform) {
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            if ($subform.parent().hasClass("subrecord-form-wrapper")) {
              $subform.parent().remove()
            } else {
              $subform.remove();
            }

            $this.parents("form:first").triggerHandler("form-changed");
            $(document).triggerHandler("deleted.subrecord", [$this]);
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

        var callback = function($subform) {
          var $topLevelNoteTypeSelector = $("select.multipart-note-type", $subform);
          $topLevelNoteTypeSelector.change(changeNoteTemplate);
          initRemoveActionForSubRecord($subform);
        }

        initNoteType($subform, 'template_note_multipart_selector', true, '.add-sub-note-btn', callback);
      };

      initialisers.note_bioghist = function($subform) {

        var callback = function($subform) {
          var $topLevelNoteTypeSelector = $("select.bioghist-note-type", $subform);
          $topLevelNoteTypeSelector.change(changeNoteTemplate);
          initRemoveActionForSubRecord($subform);
        }

        initNoteType($subform, 'template_note_bioghist_selector', true, '.add-sub-note-btn', callback);
      };

      var initNoteForm = function($noteform, for_a_new_form) {
        if ($noteform.hasClass("initialised")) {
          return;
        }
        $noteform.addClass("initialised")


        if (!for_a_new_form) initRemoveActionForSubRecord($noteform);

        dropdownFocusFix($noteform);

        var $list = $("ul.subrecord-form-list:first", $noteform);

        AS.initSubRecordSorting($list);

        var note_type = $noteform.data("type");
        if (initialisers[note_type]) {
          initialisers[note_type]($noteform);
        }

        initContentList($noteform);
      };

      var changeNoteTemplate = function() {
        var $subform = $(this).parents("[data-index]:first");

        var $noteFormContainer = $(".selected-container", $subform);

        var $parent_subrecord_list = $subform.parents(".subrecord-form-list:first");

        if ($(this).val() === "") {
          $noteFormContainer.html(AS.renderTemplate("template_note_type_nil"));
          return;
        }

        var $note_form = $(AS.renderTemplate("template_"+$(this).val(), {
          path: AS.quickTemplate($parent_subrecord_list.data("name-path"), {index: $subform.data("index")}),
          id_path: AS.quickTemplate($parent_subrecord_list.data("id-path"), {index: $subform.data("index")}),
          index: "${index}"
        }));

        $note_form.data("type");
        $note_form.attr("data-index", $subform.data("index"));

        var matchingNoteType = $(".note-type option:contains('"+$(":selected", this).text()+"')", $note_form);
        $(".note-type", $note_form).val(matchingNoteType.val());

        initNoteForm($note_form, true);

        $noteFormContainer.html($note_form);

        $(":input:visible:first", $note_form).focus();

        $subform.parents("form:first").triggerHandler("form-changed");
        $(document).triggerHandler("subrecordcreated.aspace", ["note", $note_form]);
      };

      var createTopLevelNote = function(event) {
        event.preventDefault();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);

        var $subform = $(AS.renderTemplate("template_note_type_selector"));

        $subform = $("<li>").data("type", $subform.data("type")).append($subform);
        $subform.attr("data-index", index);

        $target_subrecord_list.append($subform);

        AS.initSubRecordSorting($target_subrecord_list);

        $(document).triggerHandler("subrecordcreated.aspace", ["note", $subform]);

        $(":input:visible:first", $subform).focus();

        $this.parents("form:first").triggerHandler("form-changed");

        initRemoveActionForSubRecord($subform);

        var $topLevelNoteTypeSelector = $("select.top-level-note-type", $subform);
        $topLevelNoteTypeSelector.change(changeNoteTemplate);

        index++;
      };

      $(".subrecord-form-heading:first .btn", $this).click(createTopLevelNote);

      // initialising forms
      var $list = $("ul.subrecord-form-list:first", $this)
      AS.initSubRecordSorting($list);
      AS.initAddAsYouGoActions($this, $list);

      if ($(".subrecord-form-list > .subrecord-form-wrapper > .subrecord-form-fields", $this).length) {
        $(".subrecord-form-list > .subrecord-form-wrapper > .subrecord-form-fields", $this).each(function() {
          initNoteForm($(this));
        });
        $(".subrecord-form-inline", $this).each(function() {
          initRemoveActionForSubRecord($(this));
        });
      }
    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#notes.subrecord-form:not(.initialised)").init_notes_form();
    });

    $("#notes.subrecord-form:not(.initialised)").init_notes_form();
  });

});
