$(function() {

  var initTermForm = function($form) {

    if ($form.data("terms") === "initialised") {
      return;
    }

    $form.data("terms", "initialised");

    var itemDisplayString = function(item) {
      var term_type = item.term_type
      if (item["_translated"] && item["_translated"]["term_type"]) {
        term_type = item["_translated"]["term_type"];
      }
      return  item.term + " ["+term_type+"]"
    };

    var termTypeAhead = AS.delayedTypeAhead(function (query, callback) {
      $.ajax({
        url: AS.app_prefix("subjects/terms/complete"),
        data: {query: query},
        type: "GET",
        success: function(terms) {
          callback(terms);
        },
        error: function() {
          callback([]);
        }
      });
    });

    $(":text", $form)
      .typeahead({
        source: termTypeAhead.handle,
        matcher: function(item) {
          return item.term && itemDisplayString(item).toLowerCase().indexOf(this.query.toLowerCase()) >= 0;
        },
        sorter: function(items) {
          return items.sort(function(a, b) {
            return a.term > b.term;
          });
        },
        highlighter: function(item) {
          return $.proxy(Object.getPrototypeOf(this).highlighter, this)(itemDisplayString(item));
        },
        updater: function(item) {
          $("select", this.$element.parents(".row-fluid:first")).val(item.term_type);
          return item.term;
        }
      });
  };


  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    if (object_name === "term") {
      initTermForm($(subform));
    }
  });

});
