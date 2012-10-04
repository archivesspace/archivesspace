$(function() {

  $.fn.init_subrecord_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var form_index = $(".subrecord-form-fields", $this).length;


      var init_subform = function() {
        var $subform = $(this);

        if ($subform.data("allow-removal") === true) {
          var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
          $subform.prepend(removeBtn);
          removeBtn.on("click", function() {
            AS.confirmSubFormDelete($(this), function() {
              $subform.remove();
              $this.parents("form:first").triggerHandler("form-changed");
              if ($(".subrecord-form-fields", $this).length === 0) {
                $(".alert", $this).show();
              }
            });
          });
        }

        $(document).triggerHandler("subrecord.new", [$this.data("object-name"), $subform]);
      };


      var init = function() {
        // add binding for creation of subforms
        $("h3 > .btn", $this).on("click", function() {
          var formEl = $(AS.renderTemplate($this.data("template-id"), {index: form_index}));
          formEl.hide();
          $(".subrecord-form-container", $this).append(formEl);
          formEl.fadeIn();
          $(".alert", $this).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, formEl)();
          $(":input:visible:first", formEl).focus();
          form_index++;
        });

        // init any existing subforms
        $(".subrecord-form-fields", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $(".subrecord-form:not(.initialised)").init_subrecord_form();
    });

    $(".subrecord-form:not(.initialised)").init_subrecord_form();
  });

});