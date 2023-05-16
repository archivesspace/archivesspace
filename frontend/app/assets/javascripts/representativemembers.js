$(function () {
  function handleRepresentativeChange($subform, isRepresentative, field_name) {
    if (isRepresentative) {
      $subform.addClass('is-representative');
    } else {
      $subform.removeClass('is-representative');
    }

    $(':input[name$="[' + field_name + ']"]', $subform).val(
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
        object_name === 'agent_contact' ||
        object_name === 'linked_agent'
      ) {
        // ANW-504: for linked agents, the field that stores the switch denoting a representative number is 'is_primary'
        var rep_field_name;
        if (object_name === 'linked_agent') {
          rep_field_name = 'is_primary';
        } else {
          rep_field_name = 'is_representative';
        }

        const $subform = $(subform);
        const $section = $subform.closest('section.subrecord-form');
        const isRepresentative =
          $(':input[name$="[' + rep_field_name + ']"]', $subform).val() === '1';
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
              handleRepresentativeChange($subform, false, rep_field_name);
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
          handleRepresentativeChange($subform, false, rep_field_name);
        });

        $section.on(eventName, function (e, representative_subform) {
          handleRepresentativeChange(
            $subform,
            representative_subform == $subform,
            rep_field_name
          );
          $('.tooltip').tooltip('hide');
        });
      }
    }
  );
});
