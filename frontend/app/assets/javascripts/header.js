$(function() {
  $('.session-actions').on('click.dropdown', function(e) {
    var $this = $(this);
    setTimeout(function() {
      $this.parent().find("input[name=username]").focus();
    }, 0);
  });


  // Login Form Handling
  var handleLoginError = function() {
    $('form.login .control-group').addClass("error");
    $("#login").removeAttr("disabled");
  };


  var handleLoginSuccess = function() {
    $('form.login .control-group').removeClass("error");
    $('form.login .alert-success').show();
    setTimeout(function() {
      document.location.reload(true);
    }, 500);
  };


  $('form.login').ajaxForm({
    dataType: "json",
    beforeSubmit: function() {
      $("#login").attr("disabled","disabled");
    },
    success: function(response, status, xhr) {
      if (response.session) {
        handleLoginSuccess();
      } else {
        handleLoginError();
      }
    },
    error: function(obj, errorText, errorDesc) {         
      handleLoginError();
    }
  });


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


  // Repo/User label sizing
  $(".nav .repository-label:not(.empty), .nav .user-label:not(.empty)").on("focus mouseenter", function() {
    var width = 5;
    $(this).find("span").each(function() {
      width += $(this).width();
    });
    $(this).css("width", width);
  }).on("blur mouseleave", function() {
      $(this).css("width", "");
  })
});