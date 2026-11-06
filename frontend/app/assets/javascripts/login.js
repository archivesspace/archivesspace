AS.LoginHelper = {
  init: function (el) {
    $(el).each(function () {
      var $form = $(this);

      var handleSuccess = function (json) {
        $('.form-group', $form).removeClass('has-error');
        AS.hideAlert($('.alert-danger', $form));
        $('.alert-success', $form).show();

        $form.trigger('loginsuccess.aspace', [json]);
      };

      var handleError = function () {
        $('.form-group', $form).addClass('has-error');
        AS.hideAlert($('.alert-success', $form));
        AS.showAndFocusAlert($('.alert-danger', $form));
        $('#login', $form).attr('disabled', null);

        $form.trigger('loginerror.aspace');
      };

      $form.ajaxForm({
        dataType: 'json',
        beforeSubmit: function () {
          AS.hideAlert($('.alert-danger', $form));
          AS.hideAlert($('.alert-success', $form));
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
