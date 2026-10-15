AS.LoginHelper = {
  init: function (el) {
    $(el).each(function () {
      var $form = $(this);

      var handleSuccess = function (json) {
        $('.form-group', $form).removeClass('has-error');
        $('.alert-success', $form).show();

        $form.trigger('loginsuccess.aspace', [json]);
      };

      var handleError = function (xhr) {
        $('.form-group', $form).addClass('has-error');
        $('.alert-danger, .alert-warning', $form).hide();
        if (xhr && xhr.status === 429) {
          $('.alert-warning', $form).show();
        } else {
          $('.alert-danger', $form).show();
        }
        $('#login', $form).attr('disabled', null);

        $form.trigger('loginerror.aspace');
      };

      $form.ajaxForm({
        dataType: 'json',
        beforeSubmit: function () {
          $('#login', $form).attr('disabled', 'disabled');
        },
        success: function (json, status, xhr) {
          if (json.session) {
            handleSuccess(json);
          } else {
            handleError();
          }
        },
        error: function (obj, errorText, errorDesc) {
          handleError(obj);
        },
      });
    });
  },
};
