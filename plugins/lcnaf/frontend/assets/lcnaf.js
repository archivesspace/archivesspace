$(function() {
  var $searchForm = $("#lcnaf_search");
  var $importForm = $("#lcnaf_import");

  var $results = $("#results");
  var $selected = $("#selected");

  var selected_lccns = {};

  var renderResults = function(json) {
    $results.empty();
    $results.append(AS.renderTemplate("template_lcnaf_result_summary", json));
    $.each(json.records, function(i, record) {
      var $result = $(AS.renderTemplate("template_lcnaf_result", {record: record, selected: selected_lccns}));
      if (selected_lccns[record.lccn]) {
        $(".alert-success", $result).removeClass("hide");
      } else {
        $("button", $result).removeClass("hide");
      }
      $results.append($result);

    });
    $results.append(AS.renderTemplate("template_lcnaf_pagination", json));
    $('pre code', $results).each(function(i, e) {hljs.highlightBlock(e)});
  };


  var selectedLCCNs = function() {
    var result = [];
    $("[data-lccn]", $selected).each(function() {
      result.push($(this).data("lccn"));
    })
    return result;
  };

  var removeSelected = function(lccn) {
    selected_lccns[lccn] = false;
    $("[data-lccn="+lccn+"]", $selected).remove();
    var $result = $("[data-lccn="+lccn+"]", $results);
    if ($result.length > 0) {
      $result.removeClass("hide");
      $result.siblings(".alert").addClass("hide");
    }

    if (selectedLCCNs().length === 0) {
      $selected.siblings(".alert-info").removeClass("hide");
      $("#import-selected").attr("disabled", "disabled");
    }
  };

  var addSelected = function(lccn, $result) {
    selected_lccns[lccn] = true;
    $selected.append(AS.renderTemplate("template_lcnaf_selected", {lccn: lccn}))

    $(".alert-success", $result).removeClass("hide");
    $("button", $result).addClass("hide");

    $selected.siblings(".alert-info").addClass("hide");
    $("#import-selected").removeAttr("disabled", "disabled");
  }

  $searchForm.ajaxForm({
    dataType: "json",
    type: "GET",
    success: function(json) {
      renderResults(json);
    }
  });


  $importForm.ajaxForm({
    dataType: "json",
    type: "POST",
    success: function(json) {
      console.log(json);
    }
  });


  $results.on("click", ".lcnaf-pagination a", function(event) {
    event.preventDefault();

    $.getJSON($(this).attr("href"), function(json) {
      $results.ScrollTo();
      renderResults(json);
    });
  }).on("click", ".lcnaf-result button", function(event) {
    var lccn = $(this).data("lccn");
    if (selected_lccns[lccn]) {
      removeSelected(lccn);
    } else {
      addSelected(lccn, $(this).closest(".lcnaf-result"));
    }
  });

  $selected.on("click", ".remove-selected", function(event) {
    var lccn = $(this).parent().data("lccn");
    removeSelected(lccn);
  });

})
