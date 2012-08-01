//= require trimpath-template-1.0.38

// initialise ajax modal
$(function() {
   var openAjaxModal = function(href) {
      $("body").append('<div class="modal hide" id="tempAjaxModal"></div>');
      $("#tempAjaxModal").load(href, function() {
         $("#tempAjaxModal").on("shown",function() {
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

// add form change detection
$(function() {
   var onFormElementChange = function(event) {
       $("#object_container form").triggerHandler("form-changed");
   }
   
   $("#object_container form :input").live("change", onFormElementChange);
   $("#object_container form :radio, .object-container form :checkbox").live("click", onFormElementChange)
});

var AS = {};

AS.templateCache = [];
AS.renderTemplate = function(templateId, data) {
   if (!AS.templateCache[templateId]) {
       var templateNode = $("#"+templateId).get(0);
       if (templateNode) {
           var firstNode = templateNode.firstChild;
           var template = null;
           // Check whether the template is wrapped in <!-- -->
           if (firstNode && (firstNode.nodeType === 8 || firstNode.nodeType === 4)) {
               template = firstNode.data.toString();
           } else {
               template = templateNode.innerHTML.toString();
           }
           // Parse the template through TrimPath and add the parsed template to the template cache
           AS.templateCache[templateId] = TrimPath.parseTemplate(template, templateId);
       }
   }
   return $(AS.templateCache[templateId].process(data));
}