$(function() {

  var initTermForm = function($form) {

    if ($form.data("terms") === "initialised") {
      return;
    }

    $form.data("terms", "initialised");

    var renderTermRow = function() {
      $(".add-term-btn", $form).css("visibility", "hidden");
      $(".remove-term-btn", $form).css("visibility", "visible");

      var index = $(".term-row", $form).length;

      var template_data = {
        path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
        id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index})
      };
      var $row = $(AS.renderTemplate("template_term", template_data));

      $target_subrecord_list.append($("<li>").append($row));

      var typeahead_data = AS.AVAILABLE_TERMS;

      var itemDisplayString = function(item) {
        return  item.term + " ["+item.term_type+"]"
      };

      $(".terms-container .row-fluid:last :text:first", $form)
        .typeahead({
          source: function(query, process) {
            return typeahead_data;
          },
          matcher: function(item) {
            return item.term && itemDisplayString(item).toLowerCase().indexOf(this.query.toLowerCase()) >= 0;
          },
          sorter: function(items) {
            return items.sort(function(a, b) {
              return a.term > b.term;
            });
          },
          highlighter: function(item) {
            return $.proxy(Object.getPrototypeOf(this).highlighter, this)(itemDisplayString(item));
          },
          updater: function(item) {
            $("select", this.$element.parents(".row-fluid:first")).val(item.term_type);
            return item.term;
          }
        })
        .focus();
      $(".terms-container .row-fluid:last .add-term-btn", $form).css("visibility", "visible");
    };


    var removeTermRow = function() {
      $(this).closest("li").remove();
      renderTermsPreview();
      if ($(".terms-container .row-fluid", $form).length === 1) {
        $(".remove-term-btn", $form).css("visibility", "hidden");
      }
      $(".terms-container .row-fluid:last .add-term-btn", $form).css("visibility", "visible");
    };


    var renderTermsPreview = function() {
      if ($('#template_terms_preview').length == 0) {
        // Don't render a preview if :show_preview is false.
        return;
      }

      var term_data = {
        terms: []
      };
      $(".terms-container .row-fluid", $form).each(function() {
        term_data.terms.push({
          term: $("input", $(this)).val(),
          term_type: $("select", $(this)).val()
        });
      });
      $(".terms-preview", $form).html(AS.renderTemplate("template_terms_preview", term_data));
    };

    $form.on("change keyup", ":input", renderTermsPreview);
    $form.on("click", ".add-term-btn", renderTermRow);
    $form.on("click", ".remove-term-btn", removeTermRow);

    var $target_subrecord_list = $(".terms-container .subrecord-form-list", $form);

    if ($(".term-row", $target_subrecord_list).length === 0) {
      renderTermRow();
      $(".terms-container .row-fluid:first .remove-term-btn", $form).css("visibility", "hidden");
    } else {
      renderTermsPreview();
      if ($(".term-row", $target_subrecord_list).length > 1) {
        $(".terms-container .row-fluid:not(:last) .add-term-btn", $form).css("visibility", "hidden");
      } else {
        $(".terms-container .row-fluid:first .remove-term-btn", $form).css("visibility", "hidden");
      }
    }
  };


  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "term" && subform.is(".subrecord-form")) {
      initTermForm($(subform));
    }
  });

});
