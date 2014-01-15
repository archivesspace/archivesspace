//= require login

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

});
