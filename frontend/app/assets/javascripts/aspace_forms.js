$(function() {

  $.fn.init_subrecord_form = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");
    });
  };


  $(document).ajaxComplete(function() {
    $(".subrecord-form.allow-add-remove:not(.initialised)").init_subrecord_form();
  });

  $(".subrecord-form.allow-add-remove:not(.initialised)").init_subrecord_form();

});