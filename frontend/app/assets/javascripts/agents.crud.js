//= require subrecord.crud
//= require notes.crud
//= require dates.crud
//= require related_agents.crud
//= require rights_statements.crud
//= require form
//= require merge_dropdown
//= require add_event_dropdown
//= require slug
//= require lightmode
//= require representativemembers.js

$(function () {
  var init_id_form = function (subform) {
    // setup agent_record_identifier form
    var $subform = $(subform);
    var $isPrimary = $(':input[name$="[primary_identifier]"]', $subform);
    // var $primarySection = $isPrimary.closest(".subrecord-form-wrapper")
    var $primarySection = $isPrimary.closest('section.subrecord-form');

    var handleIsPrimaryChange = function (val) {
      if (val) {
        $subform.addClass('primary-id');
      } else {
        $subform.removeClass('primary-id');
      }
      $isPrimary.val(val ? 1 : 0);
    };

    $('.btn-primary-id-toggle', $subform).click(function (event) {
      event.preventDefault();
      $(this).parent().off('click');

      $primarySection.triggerHandler('isprimarytoggle.aspace', [$subform]);
    });

    $primarySection.on(
      'isprimarytoggle.aspace',
      function (event, primary_id_form) {
        handleIsPrimaryChange(primary_id_form == $subform);
      }
    );

    handleIsPrimaryChange($isPrimary.val() == '1');
  };

  var init_name_form = function (subform) {
    var $subform = $(subform);
    var $checkbox = $(':checkbox[name$="[sort_name_auto_generate]"]', $subform);
    var $sortNameField = $(':input[name$="[sort_name]"]', $subform);

    if (
      typeof $sortNameField !== 'undefined' &&
      typeof $sortNameField[0] !== 'undefined'
    ) {
      var originalSortNameFieldValue = $sortNameField[0].value;
    }

    var disableSortName = function () {
      $sortNameField.attr('readonly', 'readonly');
      $sortNameField.prop('disabled', true);
      $sortNameField.attr('readonly', 'readonly');
      $userEnteredSortNameValue = $sortNameField[0].value;
      $sortNameField[0].value = $checkbox.attr('display_text_when_checked');
    };

    if ($checkbox.is(':checked')) {
      disableSortName();
    }

    $checkbox.change(function () {
      if ($checkbox.is(':checked')) {
        disableSortName();
      } else {
        $sortNameField.prop('disabled', false);
        $sortNameField.attr('readonly', null);

        if (typeof originalSortNameFieldValue !== 'undefined') {
          $sortNameField[0].value = originalSortNameFieldValue;
        } else {
          $sortNameField[0].value = $userEnteredSortNameValue;
        }
      }
    });

    // setup authoritive/display name actions
    var $authorized = $(':input[name$="[authorized]"]', $subform);
    var $displayName = $(':input[name$="[is_display_name]"]', $subform);
    var $section = $authorized.closest('section.subrecord-form');

    var handleAuthorizedChange = function (val) {
      if (val) {
        $subform.addClass('authoritive-name');
      } else {
        $subform.removeClass('authoritive-name');
      }
      $authorized.val(val ? 1 : 0);
    };
    var handleDisplayNameChange = function (val) {
      if (val) {
        $subform.addClass('display-name');
      } else {
        $subform.removeClass('display-name');
      }
      $displayName.val(val ? 1 : 0);
    };

    $('.btn-authoritive-name-toggle', $subform).click(function (event) {
      event.preventDefault();
      $(this).parent().off('click');

      $section.triggerHandler('newauthorizedname.aspace', [$subform]);
    });

    $section.on(
      'newauthorizedname.aspace',
      function (event, authorized_name_form) {
        handleAuthorizedChange(authorized_name_form == $subform);
      }
    );

    $('.btn-display-name-toggle', $subform).click(function (event) {
      event.preventDefault();
      $(this).parent().off('click');

      $section.triggerHandler('newdisplayname.aspace', [$subform]);
    });

    $section.on('newdisplayname.aspace', function (event, display_name_form) {
      handleDisplayNameChange(display_name_form == $subform);
    });

    handleAuthorizedChange($authorized.val() == '1');
    handleDisplayNameChange($displayName.val() == '1');
    selectStructuredDateSubform();
  };

  var init_linked_agent = function ($subform) {
    if ($subform.hasClass('linked_agent_initialised')) {
      return;
    } else {
      $subform.addClass('linked_agent_initialised');
    }

    $subform.find('select.linked_agent_role').on('change', function () {
      var form = $subform.find('.agent-terms');
      if ($(this).val() == 'subject') {
        form.find(':input').attr('disabled', null);
        form.show();
      } else {
        form.find(':input').attr('disabled', 'disabled');
        form.hide();
      }

      var creator_title = $subform.find('.agent-creator-title').show();
      if ($(this).val() == 'creator' || $(this).val() == 'subject') {
        creator_title.show().find(':input').attr('disabled', null);
      } else {
        creator_title.hide().find(':input').attr('disabled', 'disabled');
      }
    });

    $(document).triggerHandler('subrecordcreated.aspace', [
      'term',
      $('#terms', $subform),
    ]);
  };

  // We need to trigger this event here, since there is not tree.js to do it
  // for us.
  $(document).ready(function () {
    if ($('#form_agent').length) {
      $(document).triggerHandler('loadedrecordform.aspace', [$('#form_agent')]);
      $(document).triggerHandler('loadedrecordsubforms.aspace', [
        $('#form_agent'),
      ]);
      $('#agent_person_dates_of_existence > h3 > button').click(function () {
        selectStructuredDateSubform();
      });
    }
  });

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      if (object_name === 'name') {
        init_name_form($(subform));
      }

      if (object_name === 'agent_record_identifier') {
        init_id_form($(subform));

        // ANW-429: if this is the first agent identifier subrecord, then make sure it's set as primary
        if (
          $('#agent_person_agent_record_identifier ul').children().length == 1
        ) {
          $('.btn-primary-id-toggle').click();
        }
      }

      if (object_name === 'linked_agent') {
        var $subform = $(subform);
        init_linked_agent($subform);
        $subform.find('select.linked_agent_role').triggerHandler('change');
      }

      if (
        object_name === 'agent_function' ||
        object_name === 'agent_occupation' ||
        object_name === 'agent_place' ||
        object_name === 'agent_topic'
      ) {
        var $subj = $(subform);
        setTimeout(function () {
          if (
            $("section[id*='subjects_'] ul:last li", $subj).children().length ==
            0
          ) {
            $(
              "section[id*='subjects_'] .subrecord-form-heading .btn:last",
              $subj
            ).click();
          }
        }, 300);
      }
    }
  );
});

// Based on the value of the date_type select box, render the right subform template in place. If value is not set to single or range, then add a placeholder div for when a valid type value is selected.
var selectStructuredDateSubform = function () {
  $('.js-structured_date_select').change(function () {
    var date_type = $(this).find('select').val();

    var $this = $(this);
    var $subform = $(this).parents('[data-index]:first');
    var $target_subrecord_list = $($this).parent().find('.sdl-subrecord-form');
    var $parent_subrecord_list = $subform.parents('.subrecord-form-list:first');
    var index = $('.subrecord-form-fields', $this).length + 1;

    var $date_subform;

    if (date_type == 'range') {
      $date_subform = AS.renderTemplate(
        'template_structured_date_range_fields',
        {
          path:
            AS.quickTemplate($parent_subrecord_list.data('name-path'), {
              index: $subform.data('index'),
            }) + '[structured_date_range]',
          id_path:
            AS.quickTemplate($parent_subrecord_list.data('id-path'), {
              index: $subform.data('index'),
            }) + '_structured_date_range_',
          index: '${index}',
        }
      );
    } else if (date_type == 'single') {
      $date_subform = AS.renderTemplate(
        'template_structured_date_single_fields',
        {
          path:
            AS.quickTemplate($parent_subrecord_list.data('name-path'), {
              index: $subform.data('index'),
            }) + '[structured_date_single]',
          id_path:
            AS.quickTemplate($parent_subrecord_list.data('id-path'), {
              index: $subform.data('index'),
            }) + '_structured_date_single_',
          index: '${index}',
        }
      );
    } else {
      $date_subform = "<div class='sdl-subrecord-form'></div>";
    }

    $target_subrecord_list.replaceWith($date_subform);
    var $updated_subrecord_list = $($this).parent().find('.sdl-subrecord-form');

    $(document).triggerHandler('subrecordcreated.aspace', [
      'date',
      $updated_subrecord_list,
    ]);
    index++;
  });
};
