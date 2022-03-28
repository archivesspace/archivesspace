$(function () {
  function handleRepresentativeChange($subform, isRepresentative) {
    if (isRepresentative) {
      $subform.addClass('is-representative');
    } else {
      $subform.removeClass('is-representative');
    }

    $(':input[name$="[is_representative]"]', $subform).val(
      isRepresentative ? 1 : 0
    );

    $subform.trigger('formchanged.aspace');
  }

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      // TODO: generalize?
      if (
        object_name === 'file_version' ||
        object_name === 'instance' ||
        object_name == 'agent_contact'
      ) {
        var $subform = $(subform);
        var $section = $subform.closest('section.subrecord-form');
        var isRepresentative =
          $(':input[name$="[is_representative]"]', $subform).val() === '1';
        var local_publish_button = $subform.find('.js-file-version-publish');
        var local_make_rep_button = $subform.find('.is-representative-toggle');

        var eventName =
          'newrepresentative' + object_name.replace(/_/, '') + '.aspace';

        if (local_publish_button.prop('checked') == false) {
          local_make_rep_button.prop('disabled', true);
        } else {
          local_make_rep_button.prop('disabled', false);
        }

        $subform.find('.js-file-version-publish').click(function (e) {
          if (
            $subform.hasClass('is-representative') &&
            $(this).prop('checked', true)
          ) {
            handleRepresentativeChange($subform, false);
            $(this).prop('checked', false);
          }

          if ($(this).prop('checked') == false) {
            local_make_rep_button.prop('disabled', true);
          } else {
            local_make_rep_button.prop('disabled', false);
          }
        });

        $subform.find('.is-representative-toggle').click(function (e) {
          local_publish_button.prop('checked', true);
        });

        if (isRepresentative) {
          $subform.addClass('is-representative');
        }

        $('.is-representative-toggle', $subform).click(function (e) {
          e.preventDefault();

          $section.triggerHandler(eventName, [$subform]);
        });

        $section.on(eventName, function (e, representative_subform) {
          handleRepresentativeChange(
            $subform,
            representative_subform == $subform
          );
        });
      }
    }
  );
});
