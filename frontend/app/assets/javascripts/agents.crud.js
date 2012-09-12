$(function() {

  $.fn.init_agent_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var form_index =  $(".agent-name-fields", $this).length;

      $this.addClass("initialised");

      var addSecondaryNameForm = function() {
        $("#secondary_names_container .alert-info", $this).hide();
        form_index ++;
        $("#secondary_names_container", $this).append(AS.renderTemplate("agent_secondary_name_form_template", {index: form_index}));
      };
      $("#secondary_names h3 input[type=button]").click(addSecondaryNameForm);

      var removeSecondaryNameForm = function() {
        $(this).parents(".subform:first").remove();
        if ($("#secondary_names .subform", $this).length === 0) {
          $("#secondary_names_container .alert-info", $this).show();
        }
      };
      $("#secondary_names").on("click", ".subform-remove", removeSecondaryNameForm);


      var addContactDetailsForm = function() {
        $("#contacts_container .alert-info", $this).hide();
          form_index ++;
          $("#contacts_container", $this).append(AS.renderTemplate("agent_contact_form_template", {index: form_index}))
      };
      $("#contacts h3 input[type=button]").click(addContactDetailsForm);

      var removeContactDetailsForm = function() {
        $(this).parents(".subform:first").remove();
        if ($("#contacts .subform", $this).length === 0) {
          $("#contacts_container .alert-info", $this).show();
        }
      };
      $("#contacts").on("click", ".subform-remove", removeContactDetailsForm);

    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#new_agent:not(.initialised)").init_agent_form();
    });

    $("#new_agent:not(.initialised)").init_agent_form();
  });

});