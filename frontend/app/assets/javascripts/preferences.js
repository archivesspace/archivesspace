//= require Sortable

var sortable;

$(function() {
  
  var el = document.getElementById('note-order-preference-list');
  sortable = Sortable.create(el, {});

  $('form#new_preference').submit(function(event) {

   _.each(sortable.toArray(), function(note_type, i) {

     $('<input>').attr({
       type: 'hidden',
       id: 'preference_defaults__note_order',
       name: 'preference[defaults][note_order]['+i+']',
       value: note_type
     }).appendTo(event.target);
   });

  });

});
