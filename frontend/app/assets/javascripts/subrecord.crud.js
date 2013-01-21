//= require jquery.sortable

$(function() {

  $.fn.init_subrecord_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      $this.data("form_index", $("> .subrecord-form-container .subrecord-form-fields", $this).length);

      var init_subform = function() {
        var $subform = $(this);

        if ($subform.hasClass("initialised")) {
          return;
        }

        $subform.addClass("initialised");

        var removeBtn = $("<a href='javascript:void(0)' class='btn btn-mini pull-right subrecord-form-remove'><span class='icon-remove'></span></a>");
        $subform.prepend(removeBtn);
        removeBtn.on("click", function() {
          AS.confirmSubFormDelete($(this), function() {
            $subform.remove();
            $this.parents("form:first").triggerHandler("form-changed");
          });
        });

        AS.initSubRecordSorting($("ul.subrecord-form-list", $subform));

        $(document).triggerHandler("init.subrecord", [$subform.data("object-name") || $this.data("object-name"), $subform]);
      };


      var init = function() {
        // add binding for creation of subforms
        $("> .subrecord-form-heading > .btn", $this).on("click", function() {

          var $target_subrecord_list = $(".subrecord-form-list:first", $(this).parents(".subrecord-form:first"));

          var index_data = {
            path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: $this.data("form_index")}),
            id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: $this.data("form_index")}),
            index: "${index}"
          };

          var formEl = $(AS.renderTemplate($this.data("template"), index_data));
          formEl = $("<li>").append(formEl);
          formEl.attr("data-index", $this.data("form_index"));
          formEl.hide();

          $target_subrecord_list.append(formEl);

          formEl.fadeIn();

          // re-init the sortable behaviour
          AS.initSubRecordSorting($target_subrecord_list);

          $this.parents("form:first").triggerHandler("form-changed");

          $.proxy(init_subform, formEl)();

          //init any sub sub record forms
          $(".subrecord-form:not(.initialised)",formEl).init_subrecord_form();

          $(document).triggerHandler("new.subrecord", [$this.data("object-name"), formEl]);

          $(":input:visible:first", formEl).focus();

          $this.data("form_index", $this.data("form_index")+1);
        });

        AS.initSubRecordSorting($("ul.subrecord-form-list:first", $this));

        // init any existing subforms
        $("> .subrecord-form-container .subrecord-form-list > .subrecord-form-wrapper", $this).each(init_subform);
      };

      init();
    })
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $(".subrecord-form[data-subrecord-form]:not(.initialised)").init_subrecord_form();
    });

    $(".subrecord-form[data-subrecord-form]:not(.initialised)").init_subrecord_form();

    $(document).bind("monkeypatch.subrecord", function(event, subform) {
      $(".subrecord-form[data-subrecord-form]", subform).init_subrecord_form();
    });
  });

});