$(function() {
   $.fn.linker = function() {
      $(this).each(function() {
         var $this = $(this);

         if ($this.hasClass("initialised")) {
            return;
         }

         var config = {
             format: $this.data("format"),
             class: $this.data("class"),
             owner_class: $this.data("owner_class"),
             owner_attribute: $this.data("owner_attribute"),
             multiplicity: $this.data("multiplicity"),
             name: $this.data("name"),
             name_plural: $this.data("name_plural")
         }

         var selectedItems = $this.data("selected");

         var modal_id = "linkerModalFor_"+config.class;
         $this.addClass("initialised");

         var addEventBindings = function() {
            $(".linker").on("click", ".linker-add-button", showLinkerModal);
         }

         var showLinkerModal = function() {
            AS.openCustomModal(modal_id, "Add "+ config.name, AS.renderTemplate("linker_modal_template"));
            findItems();
            $("#"+modal_id).on("click","#addSelectedButton", addSelected);
         };

         var addSelected = function() {
             selectedItems  = [];
             $(".linker-list :input:checked", "#"+modal_id).each(function() {
                 var item = $(this).data("object");
                 selectedItems.push(item.uri);
             });
             $this.html(AS.renderTemplate("linker_selected_template", {items: selectedItems, config: config}));
             $("#"+modal_id).modal('hide');
             $this.parents("form:first").triggerHandler("form-changed");
         }

         var findItems = function() {
            $.ajax({
               url: $this.data("url"),
               type: "GET",
               dataType: "json",
               success: function(json) {
                  $("#"+modal_id).find(".linker-list").html(AS.renderTemplate("linker_list_template", {items: json, config: config, selected: selectedItems}));
               }
            })
         };

         var init = function() {
             // insert existing objects
             $this.html(AS.renderTemplate("linker_selected_template", {items: $this.data("selected"), config: config}));
         }

         init();
         addEventBindings();
      });
   };
});

$(document).ready(function() {
   $(".dynamic-content").ajaxComplete(function() {
      $(".linker:not(.initialised)").linker();
   })
   
   $(".linker:not(.initialised)").linker();
});