//= require update_monitor
//= require login

// Add session active check upon form submission
$(function () {
  var initSessionCheck = function () {
    $(this).each(function () {
      var $form = $(this);

      var checkForSession = function (event) {
        $.ajax({
          url: AS.app_prefix('has_session'),
          async: false,
          data_type: 'json',
          success: function (json) {
            if (json.has_session) {
              return true;
            } else {
              event.preventDefault();
              event.stopImmediatePropagation();

              $(":input[type='submit']", $form).attr('disabled', null);

              // we might have gotten logged out while trying to save some data in a modal,
              // e.g., a linker
              var $existingModal = $('.modal.initialised');

              if ($existingModal.length) {
                $existingModal.hide();
              }

              var $modal = AS.openAjaxModal(AS.app_prefix('login'));
              $modal.removeClass('inline-login-modal');
              var $loginForm = $('form', $modal);
              AS.LoginHelper.init($loginForm);
              $loginForm.on('loginsuccess.aspace', function (event, data) {
                // update all CSRF input fields on the page
                $(':input[name=authenticity_token]').val(data.csrf_token);

                // unbind the session check and resubmit the form
                if ($existingModal.length === 0) {
                  $form.unbind('submit', checkForSession);
                  $form.submit();
                } else {
                  $modal.hide();
                  $modal.remove();
                  $existingModal.show();
                }

                // remove the modal, the job is done.
                $modal.on('hidden', function () {
                  $modal.remove();
                });
                setTimeout(function () {
                  $modal.modal('hide');
                }, 1000);

                return false;
              });

              return false;
            }
          },
          error: function () {
            $(":input[type='submit']", $form).attr('disabled', null);
            return true;
          },
        });
      };

      $form.on('submit', checkForSession);
    });
  };

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    $.proxy(
      initSessionCheck,
      $container
        .find('form.aspace-record-form:not(.public-form)')
        .andSelf()
        .filter('form.aspace-record-form:not(.public-form)')
    )();
  });

  $.proxy(initSessionCheck, $('form.aspace-record-form:not(.public-form)'))();
});

// add form change detection
$(function () {
  var lockForm = function () {
    $(this).each(function () {
      $('.form-overlay', $(this)).height('100%').fadeIn();
      $(this).addClass('locked');
    });
  };

  var showUnlockForm = function () {
    $(this).each(function () {
      var $unlock = $(AS.renderTemplate('form_overlay_unlock_template'));
      $unlock.on('click', function (event) {
        event.preventDefault();
        event.stopImmediatePropagation();
        $(window).trigger('hashchange');
      });
      $('#archives_form_overlay', $(this)).append($unlock);
      $('.alert', $unlock).fadeIn();
    });
  };

  var ignoredKeycodes = [37, 39, 9];

  var initFormChangeDetection = function () {
    $(this).each(function () {
      var $this = $(this);

      if ($this.data('changedDetectionEnabled')) {
        return;
      }

      $this.data('form_changed', $this.data('form_changed') || false);
      $this.data('changedDetectionEnabled', true);

      // this is the overlay we can use to lock the form.
      // $('> .form-context > .row > .col-md-9', $this).prepend(
      //   '<div id="archives_form_overlay"><div class="modal-backdrop in form-overlay"></div></div>'
      // );
      // $('> .form-context > .row > .col-md-3 .form-actions', $this).prepend(
      //   '<div id="archives_form_actions_overlay" class="modal-backdrop in form-overlay"></div>'
      // );

      var onFormElementChange = function (event) {
        if (
          $(event.target).parents("*[data-no-change-tracking='true']")
            .length === 0
        ) {
          $this.trigger('formchanged.aspace');
          $this.trigger('readonlytree.aspace');
        }
      };
      $this.on('change keyup', ':input', function (event) {
        if (
          $(this).data('original_value') &&
          $(this).data('original_value') !== $(this).val()
        ) {
          onFormElementChange(event);
        } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
          onFormElementChange(event);
        }
      });

      var submitParentForm = function (e) {
        e.preventDefault();
        var input = $('<input>')
          .attr('type', 'hidden')
          .attr('name', 'ignorewarnings')
          .val('true');
        $('form.aspace-record-form').append($(input));
        $('form.aspace-record-form').submit();
        return false;
      };

      $this.on('click', ':radio, :checkbox', onFormElementChange);

      $this.on('formchanged.aspace', function (event) {
        if ($this.data('form_changed') === true) {
          event.stopPropagation();
        } else {
          $(document).bind('keydown', 'ctrl+s', submitParentForm);
          $(':input', event.target).bind('keydown', 'ctrl+s', submitParentForm);
        }
        $this.data('form_changed', true);
        $('.record-toolbar', $this).addClass('formchanged');
        $(
          '.record-toolbar [data-allow-disabled] .btn:not(.no-change-tracking)',
          $this
        )
          .addClass('disabled')
          .attr('disabled', 'disabled');
      });

      $('.createPlusOneBtn', $this).on('click', function () {
        $this.data('createPlusOne', 'true');
      });

      $this.bind('submit', function (event) {
        $this.data('form_changed', false);
        $this.data('update-monitor-paused', true);
        $this.off('change keyup formchanged.aspace');
        $(document).unbind('keydown', submitParentForm);
        $(":input[type='submit'], :input.btn-primary", $this).attr(
          'disabled',
          'disabled'
        );
        if ($(this).data('createPlusOne')) {
          var $input = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'plus_one')
            .val('true');
          $($this).append($input);
        }

        return true;
      });

      $('.record-toolbar .revert-changes .btn', $this).click(function () {
        $this.data('form_changed', false);
        return true;
      });

      $('.form-actions .btn-cancel', $this).click(function () {
        $this.data('form_changed', false);
        return true;
      });

      $(window).bind('beforeunload', function (event) {
        if ($this.data('form_changed') === true) {
          return 'Please note you have some unsaved changes.';
        }
      });

      if ($this.data('update-monitor')) {
        $(document).trigger('setupupdatemonitor.aspace', [$this]);
      } else if ($this.closest('.modal').length === 0) {
        // if form isn't opened via a modal, then clear the timeouts
        // and they will be reinitialised for that form (e.g. tree forms)
        $(document).trigger('clearupdatemonitorintervals.aspace', [$this]);
      }
    });
  };

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    $.proxy(
      initFormChangeDetection,
      $('form.aspace-record-form', $container)
    )();
  });

  // we need to lock the form because somethingis happening
  $(document).bind('lockform.aspace', function (event, $container) {
    $.proxy(lockForm, [$container])();
  });
  // and now the thing is done, so we can now allow the user to unlock it.
  $(document).bind('unlockform.aspace', function (event, $container) {
    $.proxy(showUnlockForm, [$container])();
  });

  $.proxy(initFormChangeDetection, $('form.aspace-record-form'))();
});
