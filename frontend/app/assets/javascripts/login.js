AS.LoginHelper = {
  init: function (el) {
    $(el).each(function () {
      var $form = $(this);

      var handleSuccess = function (json) {
        $('.form-group', $form).removeClass('has-error');
        $('.alert-success', $form).show();

        $form.trigger('loginsuccess.aspace', [json]);
      };

      var handleError = function () {
        $('.form-group', $form).addClass('has-error');
        $('.alert-danger', $form).show();
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
          handleError();
        },
      });
    });
  },
};
