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


      var handleSortNameType = function() {
        var sortNameInput = $(":input[name='agent[names][][sort_name]']", $(this).parents(".controls:first"));
        if ($(this).is(":checked")) {          
          sortNameInput.attr("readonly","readonly");
          $.proxy(updateAutomaticSortName, this);
        } else {
          sortNameInput.removeAttr("readonly");
        }
      };
      $this.on("click", ".sort-name-generation-type", handleSortNameType);

      var updateAutomaticSortName = function() {
        var agentFieldsContainer = $(this).parents(".agent-name-fields:first");
        if ($(":input[name$=\"[sort_name_type]\"]",agentFieldsContainer).is(":checked")) {
          var agentFields = $(":input", agentFieldsContainer);
          var template_data = {};
          agentFields.each(function() {
            var tmp = $(this).attr("name").split("[");
            var method = tmp[tmp.length-1].slice(0,-1);
            template_data[method] = $(this).val();
          });
          var agent_type = $("#agent_agent_type", $this).val();

          var sort_name_template = agent_type+"_sort_name";
          if (agent_type === "agent_person") {
            sort_name_template += "_"+template_data["direct_order"];
          }
          sort_name_template += "_template";
          $(":input[name$=\"[sort_name]\"]", agentFieldsContainer).val($.trim(AS.renderTemplate(sort_name_template, template_data)));
        }
      };
      $this.on("change", ".agent-name-fields :input:not([name~='sort_name'])", updateAutomaticSortName);

    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#new_agent:not(.initialised)").init_agent_form();
    });

    $("#new_agent:not(.initialised)").init_agent_form();
  });

});