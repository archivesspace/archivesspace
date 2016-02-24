$(function() {

  $.fn.init_interrelated_accessions_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var $target_subrecord_list = $this.closest(".subrecord-form-list");
      var index = $this.closest("[data-index]").data("index");

      $this.find('select.related-accession-type').change(function () {
        var template = "template_" + $(this).val();

        var $subsubform = $(AS.renderTemplate(template, {
          path: AS.quickTemplate($target_subrecord_list.data("name-path"), {index: index}),
          id_path: AS.quickTemplate($target_subrecord_list.data("id-path"), {index: index}),
          index: "${index}"
        }));

        var $container = $this.find('.subsubform');
        $container.empty().append($subsubform);

        $(document).triggerHandler("subrecordcreated.aspace", ["interrelated_accession", $container]);
      });

    });
  };


  $(document).ready(function() {
    $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
      $(".interrelated-accessions-form:not(.initialised)").init_interrelated_accessions_form();
    });

    $(".interrelated-accessions-form:not(.initialised)").init_interrelated_accessions_form();
  });

});
