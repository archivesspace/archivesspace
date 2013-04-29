//= require dates.crud

$(function() {

  $.fn.init_related_agents_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-fields", $this).length;


      var changeRelatedAgentForm = function(event) {
        var $target_subrecord_list = $(".subrecord-form-list:first", $this);

        var template = "template_" + $(this).val();

        var $subsubform = $(AS.renderTemplate(template, {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
          index: "${index}"
        }));

        $(".selected-container", $(this).closest(".subrecord-form-fields")).html($subsubform);

        $(document).triggerHandler("subrecordcreated.aspace",["related_agent", $subsubform])
        $(document).triggerHandler("monkeypatch.subrecord", [$subsubform]);

        index++;
      };


      var initRemoveActionForSubRecord = function($subform) {
        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            if ($subform.parent().hasClass("subrecord-form-wrapper")) {
              $subform.parent().remove()
            } else {
              $subform.remove();
            }

            $this.parents("form:first").triggerHandler("form-changed");
            $(document).triggerHandler("subrecorddeleted.aspace", [$this]);
          });
        });
      };


      var addRelatedAgentSelector = function() {
        event.preventDefault();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);
        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        var template = "template_" + selected.val();

        var $subsubform = $(AS.renderTemplate("template_related_agents_selector", {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
          index: "${index}"
        }));

        $subsubform = $("<li>").data("type", $subsubform.data("type")).append($subsubform);
        $subsubform.attr("data-index", index);
        $target_subrecord_list.append($subsubform);

        initRemoveActionForSubRecord($subsubform);

        $(document).triggerHandler("subrecordcreated.aspace",["related_agent", $subsubform])
        $(document).triggerHandler("monkeypatch.subrecord", [$subsubform]);

        $("select.related-agent-type", $subsubform).change(changeRelatedAgentForm);

        index++;
      }


      $(".add-related-agent-for-type-btn", $this).click(addRelatedAgentSelector);

      var $list = $("#related-agents-container > .subrecord-form-list");

      var $subrecord_form_fields = $("> .subrecord-form-wrapper > .subrecord-form-fields", $list);
      if ($subrecord_form_fields.length > 0) {
        $subrecord_form_fields.each(function() {
          initRemoveActionForSubRecord($(this));
        });
      }

      AS.initAddAsYouGoActions($this, $list);

    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#related_agents.subrecord-form:not(.initialised)").init_related_agents_form();
    });

    $("#related_agents.subrecord-form:not(.initialised)").init_related_agents_form();
  });


});
