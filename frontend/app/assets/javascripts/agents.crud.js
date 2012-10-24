//= require subrecord.crud

$(function() {

  $.fn.init_agent_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var form_index =  $(".subrecord-form-fields", $this).length;

      $this.addClass("initialised");

      var initSubForm = function($subform) {
        if ($subform.hasClass("initialised")) {
          return;
        }
        $subform.addClass("initialised");

        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete(removeBtn, function() {
            if ($subform.parent().hasClass("subrecord-form-wrapper")) {
              $subform.parent().remove();
            } else {
              $subform.remove();
            }
            $this.parents("form:first").triggerHandler("form-changed");
          });
        });
      };

      var addNameForm = function() {
        $("#names .alert-info", $this).hide();
        form_index ++;
        var $target_subrecord_list = $("#names .subrecord-form-list:first", $this);
        var index_data = {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: form_index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: form_index}),
          index: "${index}"
        };
        var $subform = $(AS.renderTemplate("template_"+$("#agent_agent_type_").val()+"_name", index_data));
        $subform.hide();
        $target_subrecord_list.append($subform);
        $subform.fadeIn();
        $(":input:visible:first", $subform).focus();

        initSubForm($subform)
      };

      $("#names > h3 input[type=button]").click(addNameForm);


      var addContactDetailsForm = function() {
        $("#contacts_container .alert-info", $this).hide();
        form_index ++;
        var $target_subrecord_list = $("#contacts .subrecord-form-list:first", $this);
        var index_data = {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: form_index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: form_index}),
          index: "${index}"
        };
        var $subform = $(AS.renderTemplate("template_agent_contact_details", index_data));
        $subform.hide();
        $target_subrecord_list.append($subform);
        $subform.fadeIn();
        $(":input:visible:first", $subform).focus();

        initSubForm($subform)
      };
      $("#contacts > h3 input[type=button]").click(addContactDetailsForm);


      var handleSortNameType = function() {
        var sortNameInput = $(":input[name$=\"[sort_name]\"]", $(this).parents(".controls:first"));
        if ($(this).is(":checked")) {          
          sortNameInput.attr("readonly","readonly");
          $.proxy(updateAutomaticSortName, this)();
        } else {
          sortNameInput.removeAttr("readonly");
        }
      };
      $this.on("click", ".sort-name-generation-type", handleSortNameType);

      var sortNameTemplate = function(nameFormEl) {
        var agent_type = $("#agent_agent_type_", $this).val();

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
        var agentFieldsContainer = $(this).parents(".subrecord-form-fields:first");
        if ($(":input[name$=\"[automatic]\"]",agentFieldsContainer).is(":checked")) {
          var autoSortName = $.trim(AS.renderTemplate(
                                    sortNameTemplate(agentFieldsContainer), 
                                    serializeNameFields(agentFieldsContainer)));
          $(":input[name$=\"[sort_name]\"]", agentFieldsContainer).val(autoSortName);
        }
      };
      $this.on("change", ":input:not([name~='sort_name'])", updateAutomaticSortName);

      var initSortNameType = function() {
        $(":input[name$=\"[sort_name]\"]", $this).each(function() {
          var $subform = $(this).parents(".subrecord-form-fields:first");
          // should automatic should be checked?
          var autoSortName = $.trim(AS.renderTemplate(sortNameTemplate($subform), serializeNameFields($subform)));
          var currentSortName = $(this).val();
          if (autoSortName != currentSortName) {
            $(":input[name$=\"[automatic]\"]", $subform).removeAttr("checked");
            $(":input[name$=\"[sort_name]\"]", $subform).removeAttr("readonly");
          }
        });
      }
      initSortNameType();

      $("#names .subrecord-form-fields:not(.initialised), #contacts .subrecord-form-fields:not(.initialised)", $this).each(function() {
        initSubForm($(this));
      });
    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#agent_form:not(.initialised)").init_agent_form();
    });

    $("#agent_form:not(.initialised)").init_agent_form();
  });

});
