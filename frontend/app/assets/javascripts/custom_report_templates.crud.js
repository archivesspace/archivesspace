$(function () {
  var initCustomReportTemplateForm = function () {
    $(document).on('change', '#custom_record_type', function () {
      var selected_record_type = $(this).val();

      $('.record_type').hide();
      $('.record_type.' + selected_record_type).show();

      $('li.sidebar-entry-basic_information_fields a')[0].href =
        '#' + selected_record_type + '_basic_information_fields';
      $('li.sidebar-entry-linked_records a')[0].href =
        '#' + selected_record_type + '_linked_records';
      $('li.sidebar-entry-sort_by a')[0].href =
        '#' + selected_record_type + '_sort_by';
    });
    $('#custom_record_type').trigger('change');
  };

  initCustomReportTemplateForm();
});

$(document).ready(function () {
  $('#check_all').on('click', function () {
    $(this).toggleClass('btn-success');
    $(this).toggleClass('btn-default');
    var button = document.getElementById('check_all');
    var checked = button.getAttribute('data-checked');
    var unchecked = button.getAttribute('data-unchecked');
    if (button.innerHTML === checked) {
      button.innerHTML = unchecked;
    } else {
      button.innerHTML = checked;
    }
    var checkboxes = $('input[id*="_include"][type="checkbox"]');
    if (checkboxes.prop('checked')) {
      checkboxes.prop('checked', false);
    } else {
      checkboxes.prop('checked', true);
    }
  });
});
