$(function() {

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


  // Toggle Advanced Search
  $(".nav .search-switcher").click(function(event) {
    event.stopPropagation();
    event.preventDefault();

    $(".nav .search-switcher").toggle();
    $(".advanced-search-container").slideToggle();
  });

  $(".search-switcher-hide").click(function(event) {
    event.stopPropagation();
    event.preventDefault();

    $(".nav .search-switcher").toggle();
    $(".advanced-search-container").slideUp();
  });

});
