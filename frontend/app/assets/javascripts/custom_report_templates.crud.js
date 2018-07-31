$(function() {

  var initCustomReportTemplateForm = function () {
    $(document).on('change', '#custom_record_type', function () {
      var selected_record_type = $(this).val();

      $('.record_type').hide();
      $('.record_type.' + selected_record_type).show();

      console.log('Info: ' + $('li.sidebar-entry-basic_information_fields a').length)

      $('li.sidebar-entry-basic_information_fields a')[0].href=('#'
      	+ selected_record_type + '_basic_information_fields')
      $('li.sidebar-entry-linked_records a')[0].href=('#'
      	+ selected_record_type + '_linked_records')
      $('li.sidebar-entry-sort_by a')[0].href=('#' + selected_record_type
      	+ '_sort_by')
    });
    $('#custom_record_type').trigger('change');
  };

  initCustomReportTemplateForm();
});