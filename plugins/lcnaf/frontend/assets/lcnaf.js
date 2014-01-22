$(function() {
  var $form = $("#lcnaf_search");
  var $results = $("#results");

  $form.ajaxForm({
    dataType: "json",
    type: "GET",
    success: function(json) {
      $results.empty();
      $.each(json.records, function(i, record) {
        $results.append(AS.renderTemplate("template_lcnaf_result", record));
      });
    }
  })

})