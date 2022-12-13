$(document).ready(function () {
  function setupRightsRestrictionNoteFields($subform) {
    var noteJSONModelType = $subform.data('type');

    if (noteJSONModelType == 'note_multipart') {
      var toggleRightsFields = function () {
        var noteType = $('.note-type option:selected', $subform).val();
        var $restriction_fields = $('#notes_restriction', $subform);

        if (noteType == 'accessrestrict' || noteType == 'userestrict') {
          $(':input', $restriction_fields).attr('disabled', null);
          $restriction_fields.show();

          var $restrictionTypeInput = $restriction_fields.find(
            "select[id*='_local_access_restriction_type_']"
          );
          if (noteType == 'accessrestrict') {
            $restrictionTypeInput.attr('disabled', null);
            $restrictionTypeInput.closest('.control-group').show();
          } else {
            $restrictionTypeInput.closest('.control-group').hide();
            $restrictionTypeInput.attr('disabled', 'disabled');
          }
        } else {
          $(':input', $restriction_fields).attr('disabled', 'disabled');
          $restriction_fields.hide();
        }
      };

      $('.note-type', $subform).on('change', function () {
        toggleRightsFields();
      });

      toggleRightsFields();
    }
  }

  $(document).bind(
    'subrecordcreated.aspace',
    function (event, jsonmodel_type, $subform) {
      if (jsonmodel_type == 'note') {
        setupRightsRestrictionNoteFields($subform);
      }
    }
  );

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    $container
      .find('section.notes-form.subrecord-form .subrecord-form-fields')
      .each(function () {
        setupRightsRestrictionNoteFields($(this));
      });
  });

  $('section.notes-form.subrecord-form .subrecord-form-fields').each(
    function () {
      setupRightsRestrictionNoteFields($(this));
    }
  );
});
