$(function() {
  
  $.fn.init_extent_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var form_index = $(".subform.extent-fields", $this).length;


      var init_subform = function() {
        var $subform = $(this);

        $(".subform-remove", $subform).on("click", function() {
          $subform.remove();
          $this.parents("form:first").triggerHandler("form-changed");
          if ($(".subform.extent-fields", $this).length === 0) {
            $(".alert", $this).show();
          }
        });
      };


      var init = function() {    
        // add binding for creation of subforms
        $("h3 > .btn", $this).on("click", function() {
          var extentFormEl = $(AS.renderTemplate("extent_form_template", {index: form_index++}));
          $("#extents_container", $this).append(extentFormEl);
          $(".alert", $this).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, extentFormEl)();
          $(":input:visible:first", extentFormEl).focus();
        });

        // init any existing subforms
        $(".subform.extent-fields", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#extent:not(.initialised)").init_extent_form();
    });

    $("#extent:not(.initialised)").init_extent_form();
  });

});