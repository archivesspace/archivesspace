$(function () {
  function ExtentCalculatorForm() {}

  ExtentCalculatorForm.prototype.init_form = function () {
    $('.create-extent-btn').on('click', function (event) {
      if (
        !(
          $('#extent_portion_').val() &&
          $('#extent_number_').val() &&
          $('#extent_extent_type_').val()
        )
      ) {
        alert($('#required_fields_alert_message').attr('message'));
        return;
      }

      var parent_id = '';
      if ($('#resource_extents_').length) {
        parent_id = '#resource_extents_';
      } else if ($('#accession_extents_').length) {
        parent_id = '#accession_extents_';
      } else if ($('#archival_object_extents_').length) {
        parent_id = '#archival_object_extents_';
      }
      $(parent_id + ' .subrecord-form-heading .btn').click();

      var extent_form = $(parent_id).find('.subrecord-form-fields').last();

      extent_form.find('[id$=__portion_]').val($('#extent_portion_').val());
      extent_form.find('[id$=__number_]').val($('#extent_number_').val());
      var extent_form_type_select = extent_form.find('[id$=__extent_type_]');
      if (extent_form_type_select.data('combobox')) {
        extent_form_type_select
          .data('combobox')
          .$element.val($('#extent_extent_type_').val());
        extent_form_type_select
          .data('combobox')
          .$target.val($('#extent_extent_type_').val());
      } else {
        extent_form_type_select.val($('#extent_extent_type_').val());
      }
      extent_form
        .find('[id$=__container_summary_]')
        .val($('#extent_container_summary_').val());
      extent_form
        .find('[id$=__physical_details_]')
        .val($('#extent_physical_details_').val());
      extent_form
        .find('[id$=__dimensions_]')
        .val($('#extent_dimensions_').val());

      $modal.modal('hide');
    });
  };

  var init = function () {
    $('.extent-calculator-btn').on('click', function (event) {
      var dialog_content = AS.renderTemplate(
        'extent_calculator_show_calculation_template'
      );

      $modal = AS.openCustomModal(
        'extentCalculationModal',
        'Extent Calculation',
        dialog_content,
        'large'
      );

      $.ajax({
        url: AS.app_prefix('/extent_calculator'),
        data: {
          record_uri: $('#extent_calculator_show_calculation_template').attr(
            'record_uri'
          ),
          referrer: document.location.href,
        },
        type: 'get',
        success: function (html) {
          $('#show_calculation_results').html(html);
          var extentCalculatorForm = new ExtentCalculatorForm();
          extentCalculatorForm.init_form();
        },
        error: function (jqXHR, textStatus, errorThrown) {
          var html = AS.renderTemplate(
            'template_extent_calculator_error_message',
            { message: jqXHR.responseText }
          );
          $('#show_calculation_results').html(html);
        },
      });
    });
  };

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    init();
  });
});
