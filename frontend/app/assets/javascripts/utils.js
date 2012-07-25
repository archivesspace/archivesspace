// initialise ajax modal
$(function() {
   var openAjaxModal = function(href) {
      $("body").append('<div class="modal hide" id="tempAjaxModal"></div>');
      $(tempAjaxModal).load(href, function() {
         $(tempAjaxModal).on("shown",function() {
            $(this).find("input[type!=hidden]:first").focus();
         }).on("hidden", function() {
            $(this).remove();
         }).modal('show');
         
      });
   }
   
   $("body").on("click", "[data-toggle=modal-ajax]", function(e) {
      e.preventDefault();
      openAjaxModal($(this).attr("href"));     
   });
});


// custom controls-accordion for radio driven accordion
$(function() {
   // ensure accordion is expanded for checked radios
   $(".controls-accordion input:checked").each(function() {
      $($(this).parents("label:first").attr("href")).addClass("in");
   });
   
   // ensure radio is checked for expanding accordion
   $(".controls-accordion label.radio").on("click", function() {
      $("input", this).attr("checked","checked");
   })
});
