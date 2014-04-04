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
  };


  var resizeSelectedBox = function() {
    $selected.closest(".selected-container").width($selected.closest(".span4").width() - 30);
  };


  $searchForm.ajaxForm({
    dataType: "json",
    type: "GET",
    beforeSubmit: function() {
      if (!$("#family-name-search-query", $searchForm).val()) {
          return false;
      }

      $(".btn", $searchForm).attr("disabled", "disabled").addClass("disabled").addClass("busy");
    },
    success: function(json) {
      $(".btn", $searchForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
      renderResults(json);
    }
  });


  $importForm.ajaxForm({
    dataType: "json",
    type: "POST",
    beforeSubmit: function() {
      $("#import-selected").attr("disabled", "disabled").addClass("disabled").addClass("busy");
    },
    success: function(json) {
        $("#import-selected").removeClass("busy");
        if (json.job_uri) {
            AS.openQuickModal(AS.renderTemplate("template_lcnaf_import_success_title"), AS.renderTemplate("template_lcnaf_import_success_message"));
            setTimeout(function() {
              window.location = json.job_uri;
            }, 2000);
        } else {
            // error
            $("#import-selected").removeAttr("disabled").removeClass("disabled");
            AS.openQuickModal(AS.renderTemplate("template_lcnaf_import_error_title"), json.error);
        }
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


  $(window).resize(resizeSelectedBox);
  resizeSelectedBox();
})
