//= require subrecord.crud
//= require form

$(function () {
  var init_location_form = function (form) {
    var $form = $(form);

    var newSelector = '#location';
    if ($form.attr('id') === 'new_location_batch') {
      newSelector = '#location_batch';
    }

    let $temporary = $(newSelector + '_temporary_', $form);
    let $temporaryQuestion = $(newSelector + '_temporary_question_', $form);

    if ($temporary.val() != '') {
      $temporaryQuestion.prop('checked', true);
    }

    $temporaryQuestion.on('change', function () {
      $temporary.val('');
      $temporary.prop('disabled', function (i, v) {
        return !v;
      });
    });
  };

  // This is for binding event to container_locations, which link locations to
  // resources
  // this is also for init the form in modals
  $(document).ready(function () {
    // this inits the form in the new location page
    if ($('#new_location').length > 0) {
      init_location_form($('#new_location'));
    }

    // this inits the form in the new location batch page
    if ($('#new_location_batch').length > 0) {
      init_location_form($('#new_location_batch'));
    }

    // this init the form in the modal
    $(document).bind('loadedrecordform.aspace', function (event, $container) {
      init_location_form(('#new_location', $container));
    });

    // this is for container_location, which link resources to locations
    $(document).bind(
      'subrecordcreated.aspace',
      function (event, object_name, subform) {
        if (object_name === 'container_location') {
          // just in case..lets init the form
          init_location_form($(subform));

          // if the status is change to previous,set the end date to match
          // todays date ( which is in the date's data attr )
          $('[id$=__status_]', $(subform)).bind('change', function () {
            $this = $(this);
            $endDate = $('[id$=__end_date_]', subform);
            if ($this.val() == 'previous' && $endDate.val().length == 0) {
              $endDate.val($endDate.data('date'));
            }
          });
        }
      }
    );
  });

  // initialize any linkers not delivered via subrecord
  $(document).ready(function () {
    $('.linker:not(.initialised)').linker();
  });
});
