$(function() {
  var $form = $("#lcnaf_search");
  var $results = $("#results");

  var renderResults = function(json) {
    $results.empty();
    $results.append(AS.renderTemplate("template_lcnaf_result_summary", json));
    $.each(json.records, function(i, record) {
      $results.append(AS.renderTemplate("template_lcnaf_result", record));
    });
    $results.append(AS.renderTemplate("template_lcnaf_pagination", json));
    $('pre code', $results).each(function(i, e) {hljs.highlightBlock(e)});
  };

  $form.ajaxForm({
    dataType: "json",
    type: "GET",
    success: function(json) {
      renderResults(json);
    }
  });

  $results.on("click", ".lcnaf-pagination a", function(event) {
    event.preventDefault();

    $.getJSON($(this).attr("href"), function(json) {
      $results.ScrollTo();
      renderResults(json);
    });
  })

})
