$(function() {

   $.fn.init_subject_form = function() {
      $(this).each(function() {
         var $this = $(this);

         if ($this.hasClass("initialised")) {
            return;
         };

         $this.addClass("initialised");

         var renderTermRow = function(term) {
            $(".add-term-btn", $this).hide();
            $(".remove-term-btn", $this).show();
            var $row = $(AS.renderTemplate("subjects_term_template"));
            if (term) {
               $row.find(":text").val(term.term);
               $row.find("select").val(term.term_type);
            }
            $(".terms-container", $this).append($row);
            $(".terms-container .row-fluid:last :text:first", $this)
               .typeahead($(".terms-container .row-fluid:last :text:first", $this).data())
               .focus();
            $(".terms-container .row-fluid:last .add-term-btn", $this).show();
         };

         var removeTermRow = function() {
            $(this).parents(".row-fluid:first").remove();
            renderSubjectPreview();
            if ($(".terms-container .row-fluid", $this).length === 1) {
               $(".remove-term-btn", $this).hide();
            }
            $(".terms-container .row-fluid:last .add-term-btn", $this).show();
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
         if (existingTerms) {
            if ($.isArray(existingTerms)) {
               for (var i=0;i<existingTerms.length;i++) {
                  renderTermRow(existingTerms[i]);
               }
            } else if (typeof existingTerms === "object") {
               renderTermRow(existingTerms);
            }
         } else {
            renderTermRow();
            $(".remove-term-btn", $this).hide();
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