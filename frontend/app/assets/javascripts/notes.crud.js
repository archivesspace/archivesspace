//= require mixed_content.js
//= require subrecord.collapsible.js
//= require subrecord.too_many.js
//= require notes_override.crud.js

$(function() {

  $.fn.init_notes_form = function() {

    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised") || $this.hasClass("too-many") ) {
        return;
      }
        

      var index = $(".subrecord-form-fields", $this).length;

      var initialisers = {}

      var initNoteType = function($subform, template_name, is_subrecord, button_class, init_callback) {

        $((button_class || ".add-item-btn"), $subform).click(function(event) {
          event.preventDefault();
          event.stopPropagation();

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
            initNoteForm($subsubform, false);
          }

          if (is_subrecord) {
            $(document).triggerHandler("subrecordcreated.aspace", ["note", $subsubform]);
          }

          $this.parents("form:first").triggerHandler("formchanged.aspace");

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
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-default btn-xs pull-right subrecord-form-remove'><span class='glyphicon glyphicon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            if ($subform.parent().hasClass("subrecord-form-wrapper")) {
              $subform.parent().remove()
            } else {
              $subform.remove();
              if( $(".subrecord-form-list:first", $this).children("li").length < 2 ) {
                $(".subrecord-form-heading:first .btn.apply-note-order", $this).attr("disabled", "disabled");
              }
            }

            $this.parents("form:first").triggerHandler("formchanged.aspace");
            $(document).triggerHandler("subrecorddeleted.aspace", [$this]);
          });
        });
      };


      initialisers.note_index = function($subform) {
        initNoteType($subform, "template_note_index_item");
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


      var initCollapsible = function($noteform) {

        if (!$.contains(document, $noteform[0])) {
          return;
        }

        var truncate_note_content = function(content_inputs) {
          if (content_inputs.length === 0) {
            return "&hellip;";
          }

          var text = $(content_inputs.get(0)).val();
          if (text.length <= 200) {
            return text + ((content_inputs.length > 1)?"<br/>&hellip;":"");
          }

          return $.trim(text).substring(0, 200).split(" ").slice(0, -1).join(" ") + "&hellip;";
        };

        var generateNoteSummary = function() {
          var note_data = {
            type: $("#" + id_path + "_type_ :selected", $noteform).text(),
            label: $("#" + id_path + "_label_", $noteform).val(),
            jsonmodel_type: $("> .subrecord-form-heading:first", $noteform).text(),
            summary:  truncate_note_content($(":input[id*='_content_']", $noteform))
          };
          return AS.renderTemplate("template_note_summary", note_data);
        };

        var id_path_template = $noteform.closest(".subrecord-form-list").data("id-path");
        var note_index = $noteform.closest("li").data("index");
        var id_path = AS.quickTemplate(id_path_template, {index: note_index});

        AS.initSubRecordCollapsible($noteform, generateNoteSummary)
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
        initCollapsible($noteform);
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

        $subform.parents("form:first").triggerHandler("formchanged.aspace");
        $(document).triggerHandler("subrecordcreated.aspace", ["note", $note_form]);
      };


      var applyNoteOrder = function(event) {

        event.preventDefault();
        event.stopPropagation();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);

        $.ajax({
          url: APP_PATH+"notes/note_order",
          type: "GET",
          success: function(note_order) {
            var $listed = $target_subrecord_list.children().detach()
            var sorted = _.sortBy($listed, function(li) {

              var type = $('select.note-type', $(li)).val();
              //Some note types don't have a select, so try to work it out another way
              if (_.isUndefined(type)) {
                if ($('select.top-level-note-type', $(li)).length) {
                  type = $('select.top-level-note-type', $(li)).val().replace(/^note_/, '')
                } else {
                  type = $('.subrecord-form-fields', $(li)).data('type').replace(/^note_/, '')
                }
              }

              return _.indexOf(note_order, type);
            });

            var oldOrder = _.map($listed, function(li) {
              return $(li).data("index");
            });

            var newOrder = _.map(sorted, function(li) {
              return $(li).data("index");
            });

            if (!_.isEqual(oldOrder, newOrder)) {
              $("form.aspace-record-form").triggerHandler("formchanged.aspace");
            }

            $(sorted).appendTo($target_subrecord_list);
          },
          error: function(obj, errorText, errorDesc) {
            $container.html("<div class='alert alert-error'><p>An error occurred loading note order list.</p><pre>"+errorDesc+"</pre></div>");
          }
        });

      };


      var createTopLevelNote = function(event) {

        event.preventDefault();
        event.stopPropagation();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);

        var is_inline = $this.hasClass('note-inline');
        // if it's inline, we need to bring a special template, since the
        // template has already been defined for the parent record....
        if ( is_inline == true ) {
          var form_note_type =  $this.get(0).id;
          var inline_template = "template_" + form_note_type + "_note_type_selector_inline";
          var $subform = $(AS.renderTemplate(inline_template));

        } else {
          var $subform = $(AS.renderTemplate("template_note_type_selector"));
        }

        $subform = $("<li>").data("type", $subform.data("type")).append($subform);
        $subform.attr("data-index", index);

        $target_subrecord_list.append($subform);

        AS.initSubRecordSorting($target_subrecord_list);

        if ($target_subrecord_list.children("li").length > 1) {
           $(".subrecord-form-heading:first .btn.apply-note-order", $this).removeAttr("disabled");
        }


        $(document).triggerHandler("subrecordcreated.aspace", ["note", $subform]);

        $(":input:visible:first", $subform).focus();

        $this.parents("form:first").triggerHandler("formchanged.aspace");

        initRemoveActionForSubRecord($subform);

        var $topLevelNoteTypeSelector = $("select.top-level-note-type", $subform);
        $topLevelNoteTypeSelector.change(changeNoteTemplate);

        index++;
      };

      $(".subrecord-form-heading:first .btn.add-note", $this).click(createTopLevelNote);

      $(".subrecord-form-heading:first .btn.apply-note-order", $this).click(applyNoteOrder);

      var $target_subrecord_list = $(".subrecord-form-list:first", $this);

      if ($target_subrecord_list.children("li").length > 1) {
        $(".subrecord-form-heading:first .btn.apply-note-order", $this).removeAttr("disabled");
      }
     
      var initRemoveActions = function() {
        $(".subrecord-form-inline", $this).each(function() {
          initRemoveActionForSubRecord($(this));
        });
      } 

      var initNoteForms = function($noteForm ) { 
        // initialising forms
        var $list = $("ul.subrecord-form-list:first", $this)
        AS.initSubRecordSorting($list);
        AS.initAddAsYouGoActions($this, $list);
        $(".subrecord-form-list > .subrecord-form-wrapper:visible > .subrecord-form-fields:not('.initialised')", $noteForm).each(function() {
          initNoteForm($(this), false);
        });
        initRemoveActions();
      }
      
      $existingNotes = $(".subrecord-form-list:first > .subrecord-form-wrapper", $this);
      tooManyNotes = AS.initTooManySubRecords($this, $existingNotes.length, initNoteForms );

      if (tooManyNotes === false ) {
        $this.addClass("initialised");
        initNoteForms($this);
      }
    });
  };


  $(document).ready(function() {
    $(document).bind("loadedrecordform.aspace", function(event, $container) {
      $("section.notes-form.subrecord-form:not(.initialised)", $container).init_notes_form();
    });

   // $("section.notes-form.subrecord-form:not(.initialised)").init_notes_form();
  });

});
