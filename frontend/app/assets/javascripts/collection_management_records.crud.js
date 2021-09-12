//= require subrecord.crud
//= require form

var calculate_total_processing_hours = function (form) {
  var $form = $(form)
  var phe = parseFloat(
    $(
      'input[id*="_collection_management__processing_hours_per_foot_estimate_"]',
      $form
    ).val(),
    10
  )
  var pte = parseFloat(
    $(
      'input[id*="_collection_management__processing_total_extent_"]',
      $form
    ).val(),
    10
  )

  if ($.isNumeric(phe) && $.isNumeric(pte)) {
    var tph = (phe * pte).toFixed(2)
    $(
      'input[id*="_collection_management__processing_hours_total_"]',
      $form
    ).val(tph)
  }
}

$(document).bind(
  'subrecordcreated.aspace',
  function (event, object_name, subform) {
    $(
      'input[id*="_collection_management__processing_hours_per_foot_estimate_"]',
      $(subform)
    ).bind('change', function () {
      calculate_total_processing_hours(subform)
    })
    $(
      'input[id*="_collection_management__processing_total_extent_"]',
      $(subform)
    ).bind('change', function () {
      calculate_total_processing_hours(subform)
    })
  }
)
