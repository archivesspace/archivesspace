$(function() {

  var initCustomReportTemplateForm = function () {
    $(document).on('change', '#custom_record_type', function () {
      var selected_record_type = $(this).val();

      $('.record_type').hide();
      $('.record_type.' + selected_record_type).show();
    });
    $('#custom_record_type').trigger('change');
  };

  initCustomReportTemplateForm();
});
