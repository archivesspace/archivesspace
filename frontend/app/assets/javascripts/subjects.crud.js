//= require external_documents.crud

$(function() {

  $.fn.init_subject_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");


      var renderTermRow = function(term, index) {
        $(".add-term-btn", $this).css("visibility", "hidden");
        $(".remove-term-btn", $this).css("visibility", "visible");
        if (index == null) {
            index = $(".terms-container .row-fluid", $this).length;
        }
        var $row = $(AS.renderTemplate("subjects_term_template", {index: index}));
        if (term) {
          $row.find(":text").val(term.term);
          $row.find("select").val(term.term_type);
        }
        $(".terms-container", $this).append($row);

        var typeahead_data = $(".terms-container .row-fluid:last :text:first", $this).data("source");

        var itemDisplayString = function(item) {
          return  item.term + " ["+item.term_type+"]"
        }

        $(".terms-container .row-fluid:last :text:first", $this)
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
        $(".terms-container .row-fluid:last .add-term-btn", $this).css("visibility", "visible");
      };


      var removeTermRow = function() {
        $(this).parents(".row-fluid:first").remove();
        renderSubjectPreview();
        if ($(".terms-container .row-fluid", $this).length === 1) {
          $(".remove-term-btn", $this).css("visibility", "hidden");
        }
        $(".terms-container .row-fluid:last .add-term-btn", $this).css("visibility", "visible");
      };


      var renderSubjectPreview = function() {
        var term_data = {
          terms: []
        };
        $(".terms-container .row-fluid", $this).each(function() {
          term_data.terms.push({
            term: $("input", $(this)).val(),
            term_type: $("select", $(this)).val()
          });
        });
        $(".subject-preview", $this).html(AS.renderTemplate("subjects_preview_template", term_data));
      };

      $this.on("change keyup", ":input", renderSubjectPreview);
      $this.on("click", ".add-term-btn", renderTermRow);
      $this.on("click", ".remove-term-btn", removeTermRow);

      var existingTerms = $(".terms-container", $this).data("terms");
      if (existingTerms.length > 0) {
        if ($.isArray(existingTerms)) {
          for (var i=0;i<existingTerms.length;i++) {
            renderTermRow(existingTerms[i], i);
          }
        } else if (typeof existingTerms === "object") {
          renderTermRow(existingTerms, i);
        }
      } else {
        renderTermRow();
        $(".remove-term-btn", $this).css("visibility", "hidden");
      }
    });
  };


  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $("#new_subject:not(.initialised)").init_subject_form();
    });

    $("#new_subject:not(.initialised)").init_subject_form();
  });

});