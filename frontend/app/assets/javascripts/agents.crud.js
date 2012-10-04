//= require subrecord.crud

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
        var nameSubFormEl = $(AS.renderTemplate("agent_secondary_name_form_template", {index: form_index}));
        nameSubFormEl.hide();
        $("#secondary_names_container", $this).append(nameSubFormEl);
        nameSubFormEl.fadeIn();
        $(":input:visible:first", nameSubFormEl).focus();
      };
      $("#secondary_names h3 input[type=button]").click(addSecondaryNameForm);

      var removeSecondaryNameForm = function() {
        AS.confirmSubFormDelete($(this), function(button) {
          button.parents(".subform-wrapper").remove();
          if ($("#secondary_names .subform", $this).length === 0) {
            $("#secondary_names_container .alert-info", $this).show();
          }
        });
      };
      $("#secondary_names").on("click", ".subrecord-form-remove", removeSecondaryNameForm);


      var addContactDetailsForm = function() {
        $("#contacts_container .alert-info", $this).hide();
        form_index ++;
        var contactSubFormEl = $(AS.renderTemplate("agent_contact_form_template", {index: form_index}));
        contactSubFormEl.hide();
        $("#contacts_container", $this).append(contactSubFormEl);
        contactSubFormEl.fadeIn();
        $(":input:visible:first", contactSubFormEl).focus();
      };
      $("#contacts h3 input[type=button]").click(addContactDetailsForm);

      var removeContactDetailsForm = function() {
        AS.confirmSubFormDelete($(this), function(button) {
          button.parents(".subform-wrapper").remove();
          if ($("#contacts .subform", $this).length === 0) {
            $("#contacts_container .alert-info", $this).show();
          }
        });
      };
      $("#contacts").on("click", ".subrecord-form-remove", removeContactDetailsForm);


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

      var sortNameTemplate = function(nameFormEl) {
        var agent_type = $("#agent_agent_type", $this).val();

        var data = serializeNameFields(nameFormEl);

        var sort_name_template = agent_type+"_sort_name";
        if (agent_type === "agent_person") {
          sort_name_template += "_"+data["direct_order"];
        }
        sort_name_template += "_template";

        return sort_name_template;
      }

      var serializeNameFields = function(nameFormEl) {
        var agentFields = $(":input", nameFormEl);
        var template_data = {};
        agentFields.each(function() {
          var tmp = $(this).attr("name").split("[");
          var method = tmp[tmp.length-1].slice(0,-1);
          template_data[method] = $(this).val();
        });
        return template_data;
      };

      var updateAutomaticSortName = function() {
        var agentFieldsContainer = $(this).parents(".agent-name-fields:first");
        if ($(":input[name$=\"[sort_name_type]\"]",agentFieldsContainer).is(":checked")) {
          var autoSortName = $.trim(AS.renderTemplate(
                                    sortNameTemplate(agentFieldsContainer), 
                                    serializeNameFields(agentFieldsContainer)));
          $(":input[name$=\"[sort_name]\"]", agentFieldsContainer).val(autoSortName);
        }
      };
      $this.on("change", ".agent-name-fields :input:not([name~='sort_name'])", updateAutomaticSortName);

      var initSortNameType = function() {
        $(".agent-name-fields").each(function() {
          // should sort_name_type should be checked?
          var autoSortName = $.trim(AS.renderTemplate(sortNameTemplate(this), serializeNameFields(this)));
          var currentSortName = $(":input[name$=\"[sort_name]\"]", this).val();
          if (autoSortName != currentSortName) {
            $(":input[name$=\"[sort_name_type]\"]", this).removeAttr("checked");
            $(":input[name$=\"[sort_name]\"]", this).removeAttr("readonly");
          }
        });
      }
      initSortNameType();

    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#new_agent:not(.initialised)").init_agent_form();
    });

    $("#new_agent:not(.initialised)").init_agent_form();
  });

});
