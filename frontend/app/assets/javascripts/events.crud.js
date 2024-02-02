//= require agents.crud
//= require dates.crud
//= require subrecord.crud
//= require form

$(document).ready(function () {
  $('#event_chronotype_label_').on('change', function () {
    $('.chronotype_form').hide();
    $('.chronotype_form :input').attr('disabled', 'disabled');

    var activated = $(this).val();
    $('#chronotype_' + activated + ' :input').attr('disabled', null);
    $('#chronotype_' + activated).show();
  });

  if ($('#event_timestamp_').val()) {
    $('#event_chronotype_label_').val('timestamp');
  }

  $('#event_chronotype_label_').triggerHandler('change');
  $(document).triggerHandler('subrecordcreated.aspace', [
    'date',
    $('#event_date .subrecord-form-fields'),
  ]);
});
