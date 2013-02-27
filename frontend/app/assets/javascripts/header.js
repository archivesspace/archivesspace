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

  // Show Repo popover if there are no repositories and we're on the front page
  if (window.location.pathname === APP_PATH) {
    if ($(".repository-label.has-popover.empty").length) {
      $(".repository-label.has-popover.empty").popover('show');
      $(".user-container .inset-label .popover .btn.btn-mini.dropdown-toggle").click(function() {
        $(".user-container > .input-append > .btn").trigger("click");
        setTimeout(function() {
          $(".user-container > .input-append").addClass("open");
        });
      });
      $('.navbar .btn').click(function() {
        $(".repository-label.has-popover.empty").popover('destroy');
      });
    }
  }

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

});
