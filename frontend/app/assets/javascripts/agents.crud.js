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

        // if a #names form then setup the sort_name behaviour
        if ($subform.closest("#names").length) {
          setupSortNameBehaviour($subform);
        }
      };


      var setupSortNameBehaviour = function($subform) {
        var $checkbox = $(":checkbox[name$=\"[sort_name_auto_generate]\"]", $subform);
        var $sortNameField = $(":input[name$=\"[sort_name]\"]", $subform);
        if ($checkbox.is(":checked")) {
          $sortNameField.attr("readonly","readonly");
          $sortNameField.closest(".control-group").hide();
        }

        $checkbox.change(function() {
          if ($checkbox.is(":checked")) {
            $sortNameField.attr("readonly","readonly");
            $sortNameField.closest(".control-group").hide();
          } else {
            $sortNameField.removeAttr("readonly");
            $sortNameField.closest(".control-group").show();
          }
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
        var $subform = $(AS.renderTemplate("template_"+$("#agent_agent_type_").val().replace("agent_", "name_")+"", index_data));
        $subform.hide();
        $target_subrecord_list.append($subform);
        $subform.fadeIn();
        $(":input:visible:first", $subform).focus();

        initSubForm($subform);
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
        var $subform = $(AS.renderTemplate("template_agent_contact", index_data));
        $subform.hide();
        $target_subrecord_list.append($subform);
        $subform.fadeIn();
        $(":input:visible:first", $subform).focus();

        initSubForm($subform)
      };
      $("#contacts > h3 input[type=button]").click(addContactDetailsForm);


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
