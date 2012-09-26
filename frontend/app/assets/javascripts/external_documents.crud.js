$(function() {
  
  $.fn.init_external_document_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var form_index = $(".subform.external-document-fields", $this).length;


      var init_subform = function() {
        var $subform = $(this);

        $(".subform-remove", $subform).on("click", function() {
          $subform.remove();
          $this.parents("form:first").triggerHandler("form-changed");
          if ($(".subform.external-document-fields", $this).length === 0) {
            $(".alert", $this).show();
          }
        });
      };


      var init = function() {    
        // add binding for creation of subforms
        $("h3 > .btn", $this).on("click", function() {
          var documentFormEl = $(AS.renderTemplate("external_document_form_template", {index: form_index++}));
          $("#external_documents_container", $this).append(documentFormEl);
          $(".alert", $this).hide();
          $this.parents("form:first").triggerHandler("form-changed");
          $.proxy(init_subform, documentFormEl)();
          $(":input:visible:first", documentFormEl).focus();
        });

        // init any existing subforms
        $(".subform.external-document-fields", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#external_documents:not(.initialised)").init_external_document_form();
    });

    $("#external_documents:not(.initialised)").init_external_document_form();
  });

});