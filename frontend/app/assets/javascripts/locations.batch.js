//= require form
//= require locations.crud
$(function () {
  $('button.preview-locations').on('click', function () {
    var $form = $(this).closest('form');
    AS.openCustomModal(
      'batchPreviewModal',
      $(this).text(),
      "<div class='alert alert-info'>Loading...</div>",
      'lg',
      {},
      this
    );
    $.ajax({
      url: $form.attr('action') + '?dry_run=true',
      type: 'POST',
      data: $form.serializeArray(),
      success: function (html) {
        $('.alert', '#batchPreviewModal').replaceWith(
          AS.renderTemplate('modal_quick_template', { message: html })
        );
        $(window).trigger('resize');
      },
    });
  });

  $('form#new_location_batch').submit(function () {
    $('.btn-primary', this).addClass('disabled').addClass('busy');
  });
});
