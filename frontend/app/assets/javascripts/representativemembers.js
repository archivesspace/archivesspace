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

        const $hiddenRepStateField = $(
          ':input[name$="[' + rep_field_name + ']"]',
          $subform
        );
        if ($hiddenRepStateField.length === 0) return; // ANW-1874 No hidden field, nothing to do here

        const isRepresentative = $hiddenRepStateField.val() === '1';
        const $labelBtn = $subform.find('.is-representative-label');
        const $repBtn = $subform.find('.is-representative-toggle');
        const eventName =
          'newrepresentative' + object_name.replace(/_/, '') + '.aspace';

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

  const FILE_VERSION_FLAGS = [
    {
      field: 'is_display_thumbnail',
      css: 'is-thumbnail',
      toggle: '.is-thumbnail-toggle',
      label: '.is-thumbnail-label',
    },
    {
      field: 'is_display_link',
      css: 'is-display-link',
      toggle: '.is-display-link-toggle',
      label: '.is-display-link-label',
    },
  ];

  function setFileVersionFlag($subform, flag, on) {
    $subform.toggleClass(flag.css, on);
    $subform.find(':hidden[name$="[' + flag.field + ']"]').val(on ? 1 : 0);
    $subform.trigger('formchanged.aspace');
  }

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      if (object_name !== 'file_version') return;

      const $subform = $(subform);
      const $section = $subform.closest('section.subrecord-form');
      const $pubBox = $subform.find('.js-file-version-publish');

      function updateToggles() {
        const published = $pubBox.prop('checked');
        FILE_VERSION_FLAGS.forEach(function (flag) {
          $subform.find(flag.toggle).prop('disabled', !published);
        });
      }

      FILE_VERSION_FLAGS.forEach(function (flag) {
        if (
          $subform.find(':hidden[name$="[' + flag.field + ']"]').val() === '1'
        ) {
          $subform.addClass(flag.css);
        }

        $subform.on('click', flag.toggle, function (e) {
          e.preventDefault();
          e.stopImmediatePropagation();

          $section.find('.' + flag.css).each(function () {
            setFileVersionFlag($(this), flag, false);
          });
          setFileVersionFlag($subform, flag, true);
          $('.tooltip').tooltip('hide');
        });

        $subform.on('click', flag.label, function (e) {
          e.preventDefault();
          e.stopImmediatePropagation();

          setFileVersionFlag($subform, flag, false);
          $('.tooltip').tooltip('hide');
        });
      });

      $pubBox.on('change', function () {
        if (!$pubBox.prop('checked')) {
          FILE_VERSION_FLAGS.forEach(function (flag) {
            setFileVersionFlag($subform, flag, false);
          });
        }
        updateToggles();
      });

      updateToggles();
    }
  );
});
