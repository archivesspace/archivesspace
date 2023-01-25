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
        const $subform = $(subform);
        const $section = $subform.closest('section.subrecord-form');
        const isRepresentative =
          $(':input[name$="[is_representative]"]', $subform).val() === '1';
        const $labelBtn = $subform.find('.is-representative-label');
        const $repBtn = $subform.find('.is-representative-toggle');
        const eventName =
          'newrepresentative' + object_name.replace(/_/, '') + '.aspace';

        if (object_name === 'file_version') {
          const $pubBox = $subform.find('.js-file-version-publish');

          if ($pubBox.prop('checked') == false) {
            $repBtn.prop('disabled', true);
          } else {
            $repBtn.prop('disabled', false);
          }

          $pubBox.click(function () {
            if (
              $subform.hasClass('is-representative') &&
              $(this).prop('checked', true)
            ) {
              handleRepresentativeChange($subform, false);
              $(this).prop('checked', false);
            }

            if ($(this).prop('checked') == false) {
              $repBtn.prop('disabled', true);
            } else {
              $repBtn.prop('disabled', false);
            }
          });
        }

        if (isRepresentative) {
          $subform.addClass('is-representative');
        }

        $repBtn.click(function (e) {
          e.preventDefault();
          $(this).parent().off('click');
          $section.triggerHandler(eventName, [$subform]);
        });

        $labelBtn.click(function (e) {
          e.preventDefault();
          $(this).parent().off('click');
          handleRepresentativeChange($subform, false);
        });

        $section.on(eventName, function (e, representative_subform) {
          handleRepresentativeChange(
            $subform,
            representative_subform == $subform
          );
          $('.tooltip').tooltip('hide');
        });
      }
    }
  );
});
