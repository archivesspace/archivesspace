//= require login
//= require moment

$(function() {
  $('.session-actions').on('click.dropdown', function(e) {
    var $this = $(this);
    setTimeout(function() {
      $this.parent().find("input[name=username]").focus();
    }, 0);
  });

  var $loginForm = $('form.login');
  AS.LoginHelper.init($loginForm);

  $loginForm.on("loginsuccess.aspace", function() {
    setTimeout(function() {
      document.location.reload(true);
    }, 500);
  });


  // if login dropdown is open by default (?login=true)
  // then focus the user name field
  if ($(".login-dropdown").hasClass("open")) {
    $(document).ready(function() {
      setTimeout(function() {
        $("input[name=username]").focus();
      }, 0);
    });
  }

  // Repository Action Handling
  $('.navbar').on('click', '.select-repo', function(e) {
    e.preventDefault();      
    var repo_id = $(this).text();
    $.post($(this).attr("href"), {"repo_id": repo_id}, function(html) {
      document.location = APP_PATH;
    });
  });

  // Keyboard handling for dropdown submenus
  $('.nav a').on("focus", function() {
    if ($(this).parents("li.dropdown-submenu").length) {
      $('.dropdown-menu', $(this).parent()).show();
    } else {
      $(".dropdown-submenu .dropdown-menu", $(this).parents(".nav")).css("display", "");
    }
  });
  $('.dropdown-submenu > a').on("keyup", function(event) {
    // right arrow focuses submenu
    if (event.keyCode === 39) {
      $('.dropdown-menu a:first', $(this).parent()).focus()
    }
  });
  $('.dropdown-submenu > .dropdown-menu > li > a').on("keyup", function() {
    // left arrow focuses parent menu
    if (event.keyCode === 37) {
      $("> a", $(this).parents(".dropdown-submenu:first")).focus();
    }
  });


  // Search form handling
  $(".nav .scoped-search-options a").click(function() {
    var $form = $(this).parents("form:first");
    $(":input[name='type']", $form).val($(this).data("type"));
    $form.submit();
  });


  $("select", ".nav .select-a-repository").click(function(event) {
    event.preventDefault();
    event.stopPropagation();
  });


  // if System menu is empty, then remove it
  if ($(".nav .system-menu ul li").length === 0) {
    $(".nav .system-menu").remove();
  }


  // Toggle Advanced Search
  var $advancedSearchContainer = $(".advanced-search-container");
  var $advancedSearchForm = $("form", $advancedSearchContainer);
  var $advancedSearchRowContainer = $(".advanced-search-row-container", $advancedSearchContainer);

  $(".nav .search-switcher").click(function(event) {
    event.stopPropagation();
    event.preventDefault();

    $(".nav .search-switcher span").toggleClass('glyphicon-chevron-down');
    $(".nav .search-switcher span").toggleClass('glyphicon-chevron-up');
    $advancedSearchContainer.slideToggle();
  });

  $(".search-switcher-hide").click(function(event) {
    event.stopPropagation();
    event.preventDefault();

    $(".nav .search-switcher span").removeClass('glyphicon-chevron-up');
    $(".nav .search-switcher span").addClass('glyphicon-chevron-down');
    $advancedSearchContainer.slideUp();
  });

  $advancedSearchContainer.on("click", ".advanced-search-remove-row", function(event) {
    event.stopPropagation();
    event.preventDefault();

    $(this).closest(".row").remove();

    // Ensure first row operator select only offers "NOT" value
    var $firstOpSelect = $(".advanced-search-row-container >.row:first-child .advanced-search-row-op-input");
    if ($firstOpSelect.length > 0) {
      var $newOpSelect = AS.renderTemplate("template_advanced_search_op_select", {first: true, index: $firstOpSelect.attr("name").replace("op", ""), query: {op: $firstOpSelect.val()}});
      $firstOpSelect.replaceWith($newOpSelect);
    }

    if ($(".error", $advancedSearchContainer).length == 0) {
      enableAdvancedSearch();
    }
  });

  $advancedSearchContainer.on("click", ".advanced-search-add-row", function(event) {
    event.stopPropagation();
    event.preventDefault();

    var index = $(":input[id^='v']", $advancedSearchRowContainer).length;

    var adding_as_first_row = false;
    if (index == 0) {
      adding_as_first_row = true;
    }

    while ($(":input[name='f"+index+"']", $advancedSearchContainer).length > 0) {
      index += 1;
    }

    addAdvancedSearchRow(index, $(this).data("type"), adding_as_first_row, {});

    // hide the drop down menu after clicking an option
    $(this).closest(".dropdown-menu").siblings(".advanced-search-add-row-dropdown").trigger("click");
  });


  var disableAdvancedSearch = function() {
    $advancedSearchForm.on("submit", function() {
      return false;
    });
    $(".btn-primary", $advancedSearchContainer).attr("disabled", "disabled");
  };


  var enableAdvancedSearch = function() {
    $advancedSearchForm.off("submit");
    $(".btn-primary", $advancedSearchContainer).removeAttr("disabled");
  };


  var addAdvancedSearchRow = function(index, type, first, query) {
    var field_data = {
      index: index,
      type: type,
      first: first,
      query: query
    }

    var $row = $(AS.renderTemplate("template_advanced_search_row", {field_data: field_data}));

    $advancedSearchRowContainer.append($row);

    if (type == "date") {
      $("#v"+index, $row).on("change", function(event) {
        $(this).closest(".input-group").removeClass("has-error");

        var dop = $("#dop"+index, $row);
        if (dop.val() == 'empty') {
          enableAdvancedSearch();
          return;
        }

        function isValidDate(dateString) {
          var dateRegex = /^\d\d\d\d\-\d\d-\d\d$/;
          var isValidDateString = dateRegex.test(dateString);

          if (!isValidDateString) {
            return false;
          }

          var asDate = moment(dateString).format("YYYY-MM-DD");
          if (asDate == "Invalid date") {
            return false;
          }

          return true;
        };

        if (isValidDate($(this).val())) {
          enableAdvancedSearch();
        } else {
          $(this).closest(".input-group").addClass("has-error");
          disableAdvancedSearch();
        }
      });
    }

    $(document).trigger("initadvancedsearchrow.aspace", [field_data, $row]);
    $(document).trigger("initdatefields.aspace", [$row]);
    $(document).trigger("initcomboboxfields.aspace", [$row]);
  };

  if ($advancedSearchRowContainer.length > 0) {
    // render the rows for existing queries
    $.each($advancedSearchRowContainer.data("queries"), function(i, query) {
      addAdvancedSearchRow(i, query["type"], i == 0, query);
    });
  }
});
