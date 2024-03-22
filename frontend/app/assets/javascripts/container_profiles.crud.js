//= require form
//= require space_calculator

$(document).ready(function () {
  new SpaceCalculatorForButton($('#showSpaceCalculator'));
  $(document).triggerHandler('loadedrecordform.aspace', [
    $('#new_container_profile'),
  ]);
});
