AS.LoginHelper = {
  init: function(el) {
    $(el).each(function() {
      var $form = $(this);

      var handleSuccess = function(json) {
        $(".control-group", $form).removeClass("error");
        $(".alert-success", $form).show();

        $form.trigger("loginsuccess.aspace", [json]);
      };

      var handleError = function() {
        $(".control-group", $form).addClass("error");
        $("#login", $form).removeAttr("disabled");

        $form.trigger("loginerror.aspace");
      };

      $form.ajaxForm({
        dataType: "json",
        beforeSubmit: function() {
          $("#login", $form).attr("disabled","disabled");
        },
        success: function(json, status, xhr) {
          if (json.session) {
            handleSuccess(json);
          } else {
            handleError();
          }
        },
        error: function(obj, errorText, errorDesc) {
          handleError();
        }
      });
    });
  }
};