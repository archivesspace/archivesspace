//= require subrecord.crud
//= require notes.crud
//= require dates.crud
//= require related_agents.crud
//= require form
//= require merge_dropdown

$(function() {

  var init_name_form = function(subform) {
    var $subform = $(subform);
    var $checkbox = $(":checkbox[name$=\"[sort_name_auto_generate]\"]", $subform);
    var $sortNameField = $(":input[name$=\"[sort_name]\"]", $subform);

    // we are migrating away from dates in the name form. 
    // but we want existing data to persist in the form until we migrate off
    // so, this code hides dates if there is no value.
    var dates = $(":input[name$=\"[dates]\"]", $subform);
    if ( dates.val() == "") { 
      dates.closest(".form-group").hide();
    }

    var disableSortName = function() {
      $sortNameField.attr("readonly","readonly");
      $sortNameField.prop('disabled', true);
      $sortNameField.attr("readonly","readonly");
      $userEnteredSortNameValue = $sortNameField[0].value;
      $sortNameField[0].value = $checkbox.attr("display_text_when_checked");
    }


    if ($checkbox.is(":checked")) {
      disableSortName();
    }

    $checkbox.change(function() {
      if ($checkbox.is(":checked")) {
        disableSortName();
      } else {
        $sortNameField.prop('disabled', false);
        $sortNameField.removeAttr("readonly");
        $sortNameField[0].value = $userEnteredSortNameValue;
      }
    });


    // setup authoritive/display name actions
    var $authorized = $(":input[name$=\"[authorized]\"]", $subform);
    var $displayName = $(":input[name$=\"[is_display_name]\"]", $subform);
    var $section = $authorized.closest("section.subrecord-form");

    var handleAuthorizedChange = function(val) {
      if (val) {
        $subform.addClass("authoritive-name");
      } else {
        $subform.removeClass("authoritive-name");
      }
      $authorized.val(val ? 1 : 0);
    }
    var handleDisplayNameChange = function(val) {
      if (val) {
        $subform.addClass("display-name");
      } else {
        $subform.removeClass("display-name");
      }
      $displayName.val(val ? 1 : 0);
    }

    $(".btn-authoritive-name-toggle", $subform).click(function(event) {
      event.preventDefault();

      $section.triggerHandler("newauthorizedname.aspace", [$subform])
    });

    $section.on("newauthorizedname.aspace", function(event, authorized_name_form) {
      handleAuthorizedChange(authorized_name_form == $subform);
    });

    $(".btn-display-name-toggle", $subform).click(function(event) {
      event.preventDefault();

      $section.triggerHandler("newdisplayname.aspace", [$subform])
    });

    $section.on("newdisplayname.aspace", function(event, display_name_form) {
      handleDisplayNameChange(display_name_form == $subform);
    });

    handleAuthorizedChange($authorized.val() == "1");
    handleDisplayNameChange($displayName.val() == "1");
  };



  var init_linked_agent = function($subform) {
    if ($subform.hasClass("linked_agent_initialised")) {
      return;
    } else {
      $subform.addClass("linked_agent_initialised");
    }

    $subform.find('select.linked_agent_role').on('change', function () {
      var form = $subform.find('.agent-terms');
      if ($(this).val() == 'subject') {
        form.find(':input').removeAttr('disabled');
        form.show();
      } else {
        form.find(':input').attr('disabled', 'disabled');
        form.hide();
      }

      var creator_title = $subform.find('.agent-creator-title').show();
      if ($(this).val() == 'creator') {
        creator_title.show().find(':input').removeAttr('disabled');
      } else {
        creator_title.hide().find(':input').attr('disabled', 'disabled');
      }
    });

    $(document).triggerHandler("subrecordcreated.aspace", ["term", $("#terms", $subform)]);
  };



  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "name") {
      init_name_form($(subform));
    }

    if (object_name === "linked_agent") {
      var $subform = $(subform);
      init_linked_agent($subform);
      $subform.find('select.linked_agent_role').triggerHandler('change');
    }
  });

});
