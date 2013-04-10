$(function() {

  $.fn.init_related_agents_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var index = $(".subrecord-form-fields", $this).length;


      var addRelatedAgent = function(event) {
        event.preventDefault();

        var $target_subrecord_list = $(".subrecord-form-list:first", $this);
        var selected = $("option:selected", $(this).parents(".dropdown-menu"));
        var template = "template_" + selected.val();

        var $subsubform = $(AS.renderTemplate(template, {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
          index: "${index}"
        }));

        $subsubform = $("<li>").data("type", $subsubform.data("type")).append($subsubform);
        $subsubform.attr("data-index", index);
        $target_subrecord_list.append($subsubform);

        initRemoveActionForSubRecord($subsubform);

        $(document).triggerHandler("new.subrecord",["related_agent", $subsubform])

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
            $(document).triggerHandler("deleted.subrecord", [$this]);
          });
        });
      };


      $(".add-related-agent-for-type-btn", $this).click(addRelatedAgent);

      if ($(".subrecord-form-list > .subrecord-form-wrapper > .subrecord-form-fields", $this).length) {
        $(".subrecord-form-fields", $this).each(function() {
          initRemoveActionForSubRecord($(this));
        });
      }

    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#related_agents.subrecord-form:not(.initialised)").init_related_agents_form();
    });

    $("#related_agents.subrecord-form:not(.initialised)").init_related_agents_form();
  });


});
