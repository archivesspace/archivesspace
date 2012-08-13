//= require jquery.tokeninput

$(function() {
   $.fn.linker = function() {
      $(this).each(function() {
         var $this = $(this);

         if ($this.hasClass("initialised")) {
            return;
         }

         $this.addClass("initialised");

         var config = {
             url: $this.data("url"),
             format: $this.data("format"),
             class: $this.data("class"),
             owner_class: $this.data("owner_class"),
             owner_attribute: $this.data("owner_attribute"),
             multiplicity: $this.data("multiplicity"),
             name: $this.data("name"),
             name_plural: $this.data("name_plural")
         };

         var formatResults = function(results) {
            var formattedResults = [];
            $.each(results, function(index, obj) {
               formattedResults.push({
                  name: AS.quickTemplate(config.format, obj),
                  id: obj.uri
               });
            })
            return formattedResults;
         }

         var init = function() {
             $this.tokenInput(config.url, {
                animateDropdown: false,
                preventDuplicates: true,
                allowFreeTagging: false,
                onCachedResult: formatResults,
                onResult: formatResults,
                tokenFormatter: function(item) {                   
                   return AS.renderTemplate("linker_selectedtoken_template", {item: item, config: config});
                },
                prePopulate: $this.data("selected").map(function(s) {return {
                   id: s,
                   name: s
                }})
             });
         }

         init();
      });
   };
});

$(document).ready(function() {
   $(".dynamic-content").ajaxComplete(function() {
      $(".linker:not(.initialised)").linker();
   })
   
   $(".linker:not(.initialised)").linker();
});