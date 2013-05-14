$(function() {

  $.fn.init_rapid_data_entry_form = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $(document).triggerHandler("subrecordcreated.aspace", ["rde", $this]);
      $(document).triggerHandler("subrecordmonkeypatch.aspace", [$this]);
    });
  };


  $(document).bind("rdeinit.aspace", function(event, rdeform) {
    rdeform.init_rapid_data_entry_form();
  });

});