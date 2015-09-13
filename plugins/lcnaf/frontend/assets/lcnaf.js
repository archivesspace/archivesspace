$(function() {
  var $searchForm = $("#lcnaf_search");
  var $importForm = $("#lcnaf_import");

  var $results = $("#results");
  var $selected = $("#selected");

  var $serviceSelector = $("input[name='lcnaf_service']");

  var selected_lccns = {};

  var renderResults = function(json) {
    decorateResults(json);

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


  var decorateResults = function(resultsJson) {
    //stringify the query here so templates don't need
    //to worry about SRU vs OpenSearch
    if (typeof(resultsJson.query) === 'string') {
      // just use sru's family_name as the 
      // sole openSearch field
      resultsJson.queryString = '?family_name=' + resultsJson.query + '&lcnaf_service=' + $("input[name='lcnaf_service']:checked").val();
    } else {
       if ( resultsJson.query.query['local.GivenName'] === undefined ) {
        resultsJson.query.query['local.GivenName'] = "";  
      }
      resultsJson.queryString = '?family_name=' + resultsJson.query.query['local.FamilyName'] + '&given_name=' + resultsJson.query.query['local.GivenName'] + '&lcnaf_service=' + $("input[name='lcnaf_service']:checked").val();
    }
  }


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
      $(".alert-success", $result).removeClass("alert-success").addClass("alert-info");
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
    $("button.select-record", $result).addClass("hide");
    $(".alert-info", $result).removeClass("alert-info").addClass("alert-success");

    $selected.siblings(".alert-info").addClass("hide");
    $("#import-selected").removeAttr("disabled", "disabled");
  };


  var resizeSelectedBox = function() {
    $selected.closest(".selected-container").width($selected.closest(".col-md-4").width() - 30);
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
    },
    error: function(err) {
      $(".btn", $searchForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
      var errBody = err.hasOwnProperty("responseText") ? err.responseText.replace(/\n/g, "") : "<pre>" + JSON.stringify(err) + "</pre>";
      AS.openQuickModal(AS.renderTemplate("template_lcnaf_search_error_title"), JSON.stringify(errBody));
    }
  });


  $importForm.ajaxForm({
    dataType: "json",
    type: "POST",
    beforeSubmit: function(data, $form, options) {

      data.push({
        name: 'lcnaf_service',
        value:   $("input[name='lcnaf_service']:checked").val(),
      });

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
        $("#import-selected").removeAttr("disabled").removeClass("busy")
        AS.openQuickModal(AS.renderTemplate("template_lcnaf_import_error_title"), json.error);
      }
    },
    error: function(err) {
      $(".btn", $importForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
      var errBody = err.hasOwnProperty("responseText") ? err.responseText.replace(/\n/g, "") : "<pre>" + JSON.stringify(err) + "</pre>";
      AS.openQuickModal(AS.renderTemplate("template_lcnaf_import_error_title"), JSON.stringify(errBody));
    }
  });


  $results.on("click", ".lcnaf-pagination a", function(event) {
    event.preventDefault();

    $.getJSON($(this).attr("href"), function(json) {
      $("body").scrollTo(0); 
      renderResults(json);
    });
  }).on("click", ".lcnaf-result button.select-record", function(event) {
    var lccn = $(this).data("lccn");
    if (selected_lccns[lccn]) {
      removeSelected(lccn);
    } else {
      addSelected(lccn, $(this).closest(".lcnaf-result"));
    }
  }).on("click", ".lcnaf-result button.show-record", function(e) {
         e.preventDefault();
         $(this).siblings(".lcnaf-marc").removeClass("hide");
         $(this).addClass("hide");     
  }); 

  $selected.on("click", ".remove-selected", function(event) {
    var lccn = $(this).parent().data("lccn");
    removeSelected(lccn);
  });


  $serviceSelector.on("click", function(event) {
    if ($selected.children().length > 0) {
      event.preventDefault();
      AS.openQuickModal(AS.renderTemplate("template_lcnaf_service_locked_title"), AS.renderTemplate("template_lcnaf_service_locked_message"));
    } else {
      $("#lcnaf_search input.lcnaf-name-input").val(''); 
      $('#given-name-search-query').prop('disabled', function(i, v) { return !v; });
      $('.btn', '.lcnaf-result').prop('disabled', function(i, v) { return !v; });
    }
  });


  $(window).resize(resizeSelectedBox);
  resizeSelectedBox();
})
