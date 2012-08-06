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
         if (response.hasOwnProperty("error")) {
            handleLoginError();
         } else {
             handleLoginSuccess();
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
         $('.navbar .repository-container').replaceWith(html);
      });
   });

});
