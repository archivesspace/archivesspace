//= require Sortable

var sortable;

$(function () {
  var el = document.getElementById("note-order-preference-list");
  sortable = Sortable.create(el, {});

  $("form#new_preference").submit(function (event) {
    // .toArray() via Sortable
    sortable.toArray().forEach(function (noteType, i) {
      $("<input>")
        .attr({
          type: "hidden",
          id: "preference_defaults__note_order",
          name: "preference[defaults][note_order][" + i + "]",
          value: noteType,
        })
        .appendTo(event.target);
    });
  });
});
