// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap

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

//= require header