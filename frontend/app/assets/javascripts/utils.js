//= require trimpath-template-1.0.38
//= require bootstrap-datepicker
//= require bootstrap-combobox
//= require bootstrap-tagsinput

var AS = {}; // eslint-disable-line

// initialise ajax modal
$(function () {
  AS.openAjaxModal = function (href) {
    $('body').append('<div class="modal" id="tempAjaxModal"></div>');

    var $modal = $('#tempAjaxModal');

    $.ajax({
      url: href,
      async: false,
      success: function (html) {
        if ($(html).hasClass('modal')) {
          $modal.remove();
          $modal = $(html);

          $('body').append($modal);
        } else {
          $modal.append(html);
        }

        $modal
          .on('shown.bs.modal', function () {
            $modal.find('input[type!=hidden]:first').focus();
          })
          .on('hidden.bs.modal', function () {
            $modal.remove();
          });

        $modal.modal('show');
      },
    });

    return $modal;
  };

  $('body').on('click', '[data-toggle=modal-ajax]', function (e) {
    e.preventDefault();
    AS.openAjaxModal($(this).attr('href'));
  });
});

// add four part indentifier behaviour
$(function () {
  var initIdentifierFields = function (scope) {
    scope = scope || $(document.body);
    $('form:not(.navbar-form) .identifier-fields:not(.initialised)', scope).on(
      'keyup',
      ':input',
      function (event) {
        $(this).addClass('initialised');
        var currentInputIndex = $(event.target).index();
        $(event.target)
          .parents('.identifier-fields:first')
          .find(':input:eq(' + (currentInputIndex + 1) + ')')
          .each(function () {
            if (
              $(event.target).val().length === 0 &&
              $(this).val().length === 0
            ) {
              $(this).attr('disabled', 'disabled');
            } else {
              $(this).attr('disabled', null);
            }
          });
      }
    );
  };
  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initIdentifierFields($container);
  });
  initIdentifierFields();
});

// sidebar action
$(function () {
  var getSubMenuHTML = function (numberOfRecords) {
    if (numberOfRecords < 1) {
      return '';
    } else {
      return $(
        "<span class='nav-list-record-count badge'>" +
          numberOfRecords +
          '</span>'
      );
    }
  };

  var refreshSidebarSubMenus = function () {
    if ($('.readonly-context:first').length > 0) {
      // this could be a read only page... so don't
      // show the sub record bits
      return;
    }
    $('.nav-list-record-count').remove();
    $('#archivesSpaceSidebar .as-nav-list > li:not(.sidebar-heading)').each(
      function () {
        var $nav = $(this);
        var $link = $('a', $nav);
        var $section = $($link.attr('href'));
        var $items = $('.subrecord-form-list:first > li', $section);

        // Do not add a badge count to sidebar heading items (with class .sidebar-heading) -- only to entry items (with class .sidebar-entry-XXX)
        if (!$nav.hasClass('sidebar-heading')) {
          var $submenu = getSubMenuHTML($items.length);
          $link.append($submenu);
        }
      }
    );
  };

  var clearSelected = function () {
    $('#archivesSpaceSidebar .as-nav-list > li:not(.sidebar-heading)').each(
      function () {
        $(this).attr('aria-selected', 'false');
      }
    );
  };

  var initSidebar = function () {
    $('#archivesSpaceSidebar:not(.initialised)').each(function () {
      $('a', $(this)).click(function (e) {
        clearSelected();
        $(this).parent().attr('aria-selected', 'true');
      });

      $(this).addClass('initialised');
    });
    refreshSidebarSubMenus();
  };

  initSidebar();

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initSidebar();
  });

  $(document).bind(
    'subrecordcreated.aspace subrecorddeleted.aspace formerrorready.aspace',
    function () {
      if ($('#archivesSpaceSidebar .nav-list.initialised').length > 0) {
        refreshSidebarSubMenus();
        // refresh scrollspy offsets.. as they are probably wrong now that things have changed in the form
        $('[data-spy="scroll"]').scrollspy('refresh');
      }
    }
  );
  $(document).bind('resize.tree', function () {
    // refresh scrollspy offsets.. as they are probably wrong now that things have changed in the form
    $('[data-spy="scroll"]').scrollspy('refresh');
  });
});

// date fields and datepicker initialisation
$.fn.combobox.defaults.template =
  '<div class="combobox-container input-group"><input type="hidden" /><input type="text" autocomplete="off"/><span class="input-group-btn btn dropdown-toggle" data-dropdown="dropdown"><span class="caret"/><span class="combobox-clear"><span class="icon-remove"></span></span></span></div>';
$(function () {
  var initDateFields = function (scope) {
    scope = scope || $(document.body);
    $('.date-field:not(.initialised)', scope).each(function () {
      var $dateInput = $(this);

      if ($dateInput.parent().is('.input-group')) {
        $dateInput.parent().addClass('date');
      } else {
        $dateInput.wrap("<div class='input-group date'></div>");
      }

      $dateInput.addClass('initialised');

      // ANW-170, ANW-490: Opt-in to datepicker
      var $datepickerToggle = $(`
        <div class="input-group-append">
          <button
            class="btn btn-default"
            type="button"
            title="${$(this).data('label')}"
          >
            <i class='glyphicon glyphicon-calendar'></i>
          </button>
        </div>
      `);

      $dateInput.after($datepickerToggle);

      let enableDatepicker = false;

      $datepickerToggle.on('click', function () {
        enableDatepicker = !enableDatepicker;
        if (enableDatepicker) {
          $(this).addClass('datepicker-enabled');
          $dateInput.datepicker($dateInput.data());
          $dateInput.trigger('focus').trigger('select');
        } else {
          $(this).removeClass('datepicker-enabled');
          $dateInput.datepicker('destroy');
        }
      });
    });
  };
  initDateFields();
  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initDateFields($container);
  });
  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      initDateFields(subform);
    }
  );
  $(document).bind('initdatefields.aspace', function (event, container) {
    initDateFields(container);
  });
});

// select fields and combobox initialisation
$(function () {
  var initComboboxFields = function (scope) {
    scope = scope || $(document.body);
    $('select[data-combobox]:not(.initialised)', scope).each(function () {
      var $selectInput = $(this);
      $selectInput.data('combobox', null).addClass('initialised');
      $selectInput.combobox();
    });
  };
  initComboboxFields();

  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initComboboxFields($container);
  });
  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      initComboboxFields(subform);
    }
  );
  $(document).bind('initcomboboxfields.aspace', function (event, container) {
    initComboboxFields(container);
  });
});

// any element with a popover!
$(function () {
  var initPopovers = function (scope) {
    scope = scope || $(document.body);
    $('.has-popover:not(.initialised)', scope).each(function () {
      var $this = $(this);

      // ANW-1325: Ensure tooltip content is focusable/hoverable by inserting in the DOM
      // right after the triggering element.
      var popoverOptions = {
        delay: { show: 0, hide: 200 }, // if the popover contains a link, allow a few moments for that click to count
        container: 'body',
      };
      $this.popover(popoverOptions).addClass('initialised');

      // ANW-1325: hide popovers if escape key pressed
      $('.has-popover.initialised').on('show.bs.popover', function () {
        $(document).keydown(function (e) {
          if (e.keyCode === 27) $this.popover('hide');
        });
      });
    });
  };
  initPopovers();
  $(document).bind(
    'loadedrecordform.aspace init.popovers',
    function (event, $container) {
      initPopovers($container);
    }
  );
  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      initPopovers(subform);
    }
  );
});

// any element with a tooltip!
$(function () {
  var initTooltips = function (scope) {
    scope = scope || $(document.body);
    $('.has-tooltip:not(.initialised)', scope).each(function () {
      var $this = $(this);

      var helpTooltips =
        $this.data('trigger') === 'manual' &&
        ($this.is('label.control-label') ||
          $this.is('.btn-with-tooltip') ||
          $this.is('.subrecord-form-heading-label'));

      // ANW-1325: Ensure tooltip content is focusable/hoverable by inserting in the DOM
      // right after the triggering element.  Skipping `helpTooltips`, since those are
      // made sticky in the block below.
      var tooltipOptions = {
        container: !helpTooltips ? $this : 'body',
      };
      $this.tooltip(tooltipOptions).addClass('initialised');

      // ANW-1325: hide popovers if escape key pressed
      $('.has-tooltip.initialised').on('show.bs.tooltip', function () {
        $(document).keydown(function (e) {
          if (e.keyCode === 27) $this.tooltip('hide');
        });
      });

      // for manual ArchiveSpace help tooltips
      if (helpTooltips) {
        var openedViaClick = false;
        var showTimeout, hideTimeout;

        var onMouseEnter = function () {
          if (openedViaClick) return;

          clearTimeout(hideTimeout);
          showTimeout = setTimeout(function () {
            showTimeout = null;
            $this.tooltip('show');
          }, $this.data('delay') || 500);
          $this.off('mouseleave').on('mouseleave', onMouseLeave);
        };

        var onMouseLeave = function () {
          if (showTimeout) {
            clearTimeout(showTimeout);
          } else {
            hideTimeout = setTimeout(function () {
              $this.tooltip('hide');
            }, 100);
          }
        };

        var onClick = function () {
          clearTimeout(showTimeout);

          if (openedViaClick) {
            $this.tooltip('hide');
            openedViaClick = false;
            return;
          }

          $this.off('mouseleave');

          $this.tooltip('show');
          $('.tooltip-inner', $this.data('bs.tooltip').tip).prepend(
            '<span class="tooltip-close glyphicon glyphicon-remove-circle icon-white"></span>'
          );
          $('.tooltip-close', $this.data('bs.tooltip').tip).click(function () {
            $this.trigger('click');
          });
          openedViaClick = true;
        };

        // bind event callbacks
        $this.bind('mouseenter', onMouseEnter).click(onClick);
      }
    });
  };
  initTooltips();
  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initTooltips($container);
  });
  $(document).bind(
    'subrecordcreated.aspace',
    function (event, object_name, subform) {
      initTooltips(subform);
    }
  );

  $(document).bind('shown.bs.modal', function (events) {
    $('.modal-content').delegate($('.has-tooltip'), 'mouseenter', function () {
      initTooltips($(this));
      $('a.has-tooltip', $(this)).on('click', function () {
        window.open($(this).attr('href'));
      });
    });
  });
});

// allow click of a submenu link
$(function () {
  var initSubmenuLink = function (scope) {
    scope = scope || $(document.body);
    $(scope)
      .on(
        'click',
        ".dropdown-submenu > a[href*='javascript:void']:not(.initialised)",
        function (e) {
          e.preventDefault();
          e.stopImmediatePropagation();
          $(this).focus();
        }
      )
      .addClass('initialised');
  };
  initSubmenuLink();
  $(document).bind('loadedrecordform.aspace', function (event, $container) {
    initSubmenuLink($container);
  });
  $(document).bind(
    'subrecordcreated.aspace init.popovers',
    function (event, object_name, subform) {
      initSubmenuLink(subform);
    }
  );
});

// templates as defined in app/views/_model_/_template.html.erb are added to the DOM as HTML comments wrapped in a div. This method queries for the template we are looking for, uncomments it, and returns it for insertion back into the DOM.
AS.templateCache = [];
AS.renderTemplate = function (templateId, data, cb) {
  if (!AS.templateCache[templateId]) {
    var templateNode = $('#' + templateId).get(0);
    if (templateNode) {
      var firstNode = templateNode.firstChild;
      var template = null;
      // Check whether the template is wrapped in <!-- -->
      if (firstNode && (firstNode.nodeType === 8 || firstNode.nodeType === 4)) {
        template = firstNode.data.toString();
      } else {
        template = templateNode.innerHTML.toString();
      }
      // Parse the template through TrimPath and add the parsed template to the template cache
      AS.templateCache[templateId] = TrimPath.parseTemplate(
        template,
        templateId
      );
    }
  }
  return AS.templateCache[templateId].process(data);
};

AS.quickTemplate = function (templateHTML, data) {
  return TrimPath.parseTemplate(templateHTML).process(data);
};

AS.stripHTML = function (string) {
  if (string === null || string === undefined) {
    return '';
  }
  var rex = /(<([^>]+)>)/gi;
  return $.trim(string.replace(rex, ''));
};

AS.encodeForAttribute = function (string) {
  if (string === null || string === undefined) {
    return '';
  }
  return $.trim(string.replace(/"/g, '&quot;').replace(/(\r\n|\n|\r)/gm, ''));
};

AS.openQuickModal = function (title, message) {
  AS.openCustomModal(
    'quickModal',
    title,
    AS.renderTemplate('modal_quick_template', { message: message })
  );
};

/* AS.openCustomModal
 *  id : String - id of the modal element
 *  title : String - to be applied as the modal header
 *  contents : String/HTML - the contents of the modal
 *  size : String/false - 'full'-98% of screen, 'large' - larger modal, 'container' - match the container width, false-standard modal size
 *  modalOpts : object - any twitter bootstrap options to pass on the modal dialog upon init.
 *  initiatedBy : Element - the link/button that initiated the modal. This element will be focused again upon close.
 */
AS.openCustomModal = function (
  id,
  title,
  contents,
  modalSize,
  modalOpts,
  initiatedBy
) {
  var templateData = {
    id: id,
    title: title,
    content: '',
  };

  // phase out the class on .modal in favor of .modal-dialog
  if (modalSize === 'large') {
    templateData.dialogClass = 'modal-lg';
    templateData.fill = false;
  } else if (modalSize == 'xl') {
    templateData.dialogClass = 'modal-xl';
    templateData.fill = false;
  } else if (modalSize == 'full') {
    templateData.dialogClass = 'modal-jumbo';
    templateData.fill = false;
  } else {
    templateData.fill = modalSize;
    templateData.dialogClass = false;
  }

  $('body').append(AS.renderTemplate('modal_custom_template', templateData));
  var $modal = $('#' + id);
  $modal.find('.modal-content').append(contents);
  $modal.on('hidden.bs.modal', function () {
    $modal.remove();
    $(window).unbind('resize', resizeModal);

    if (initiatedBy) {
      $(initiatedBy).focus();
    }
  });

  var resizeModal = function () {
    var height;
    if (modalSize === 'full' || modalSize === 'large') {
      height = $(window).height() - $(window).height() * 0.03;
    } else {
      height = $(window).height() - $(window).height() * 0.2;
    }

    $modal.height(height); // -20% for 10% top and bottom margins
    var modalBodyHeight =
      $modal.height() -
      $('.modal-header', $modal).outerHeight() -
      $('.modal-footer', $modal).outerHeight() -
      95;
    $('.modal-body', $modal).height(modalBodyHeight);
    // $modal.css("marginLeft", -$modal.width() / 2);
  };

  if (modalSize) {
    $modal.on('shown resize', resizeModal);
    $(window).resize(resizeModal);
  }

  if (modalOpts) {
    $modal.modal(modalOpts);
  }

  // reset the tab index within the modal
  $modal.attr('tabindex', 0).focus();

  $modal.modal('show');

  $('.linker:not(.initialised)', $modal).linker();

  return $modal;
};

$.fn.serializeObject = function () {
  var o = {};

  $(this).each(function () {
    if ($(this).is('form')) {
      var a = $(this).serializeArray();
      $.each(a, function () {
        if (o[this.name] !== undefined) {
          if (!o[this.name].push) {
            o[this.name] = [o[this.name]];
          }
          o[this.name].push(this.value || '');
        } else {
          o[this.name] = this.value || '';
        }
      });
    } else {
      // NOTE: THIS DOESN'T WORK FOR RADIO ELEMENTS (YET)
      $(':input', this).each(function () {
        if (o[this.name] !== undefined) {
          if (!o[this.name].push) {
            o[this.name] = [o[this.name]];
          }
          o[this.name].push($(this).val() || '');
        } else {
          o[this.name] = $(this).val() || '';
        }
      });
    }
  });

  return o;
};

$.fn.setValuesFromObject = function (obj) {
  // NOTE: THIS DOESN'T WORK FOR RADIO ELEMENTS (YET)
  var $this = this;
  $.each(obj, function (name, value) {
    $("[name='" + name + "']", $this).val(value);
  });
};

AS.addControlGroupHighlighting = function (parent) {
  $('.form-group :input', parent)
    .on('focus', function () {
      $(this).parents('.form-group:first').addClass('active');
    })
    .on('blur', function () {
      $(this).parents('.form-group:first').removeClass('active');
    });
};

// confirmation behaviour for subform-remove actions
AS.confirmSubFormDelete = function (subformRemoveButtonEl, onConfirmCallback) {
  // Hide any others that were selected first
  $('.cancel-removal:visible').trigger('click');

  var confirmationEl = $(
    AS.renderTemplate('subform_remove_confirmation_template')
  );
  confirmationEl.hide();
  subformRemoveButtonEl.hide();
  subformRemoveButtonEl.before(confirmationEl);
  confirmationEl.fadeIn(function () {
    $('.confirm-removal', confirmationEl).focus();
  });

  $('.cancel-removal', confirmationEl).click(function (event) {
    confirmationEl.remove();
    subformRemoveButtonEl.fadeIn();
    return false;
  });

  $('.confirm-removal', confirmationEl).click(function (event) {
    event.preventDefault();
    event.stopPropagation();
    onConfirmCallback($(event.target));
    return false;
  });

  return false;
};

// extra add button plugin for subrecord forms
AS.initAddAsYouGoActions = function ($form, $list) {
  if ($form.data('cardinality') === 'zero_to_one') {
    // nothing to do here
    return;
  }

  // delete any existing subrecord-add-as-you-go-actions
  $('.subrecord-add-as-you-go-actions', $form).remove();

  var $asYouGo = $("<div class='subrecord-add-as-you-go-actions'></div>");
  $form.append($asYouGo);

  var numberOfSubRecords = function () {
    return $('> li', $list).length;
  };

  var bindEvents = function () {
    $form
      .off('subrecordcreated.aspace')
      .on('subrecordcreated.aspace', function () {
        $asYouGo.fadeIn();
      });

    $form
      .off('subrecorddeleted.aspace')
      .on('subrecorddeleted.aspace', function () {
        if (numberOfSubRecords() === 0) {
          $asYouGo.hide();
        }
      });
  };

  var init = function () {
    if (numberOfSubRecords() === 0) {
      $asYouGo.hide();
    }

    var btnsToReplicate = $(
      'button[data-action], .subrecord-form-heading:first > .btn, .subrecord-form-heading:first > .custom-action > .btn',
      $form
    );

    // jquery.map != Array.prototype.map
    btnsToReplicate = btnsToReplicate.map(function () {
      var $btn = $(this);
      if ($btn.hasClass('show-all') && numberOfSubRecords() < 5) return;
      else return this;
    });

    /**
     * ANW-2162: Hack around the related bug that duplicates Note subform ids
     * resulting in extra add-as-you-go buttons
     */
    btnsToReplicate = btnsToReplicate.filter(
      (i, btn) => btn.closest('section.subrecord-form') === $form[0]
    );

    var fillToPercentage = 100; // full width

    btnsToReplicate.each(function () {
      var $btn = $(this);

      var $a = $("<a href='#'>+</a>");
      var btnText = $btn.val().length ? $btn.val() : $btn.text();
      $a.css(
        'width',
        Math.floor(fillToPercentage / btnsToReplicate.length) + '%'
      );

      if (btnsToReplicate.length > 1) {
        // we need to differentiate the links
        $a.text(btnText);
        $a.addClass('has-label');
        if ($btn.hasClass('show-all')) {
          $a.addClass('show-all');
        }
      } else {
        // just add a title and we'll have a '+'
        $a.attr('title', btnText);
      }

      $a.click(function (e) {
        e.preventDefault();
        e.stopPropagation();

        $btn.trigger('click');
      });
      $asYouGo.append($a);
    });

    bindEvents();
  };

  init();
};

// Used by all tree layouts -- sets the initial height for the tree pane... but can
// be overridden by a user's cookie value
AS.DEFAULT_TREE_PANE_HEIGHT = 100;

AS.resetScrollSpy = function () {
  // reset the scrollspy plugin
  // so the headers update the status of the sidebar
  $(document.body).removeData('scrollspy');
  $(document.body).scrollspy({
    target: '#archivesSpaceSidebar',
    offset: 20,
  });
};

AS.delayedTypeAhead = function (source, delay) {
  if (!delay) {
    delay = 200;
  }

  return (function () {
    var queued_requests = [];
    var timer = undefined;

    var startTimer = function () {
      if (timer) {
        clearTimeout(timer);
      }

      timer = setTimeout(function () {
        var last_request = queued_requests.pop();
        queued_requests = [];

        source(last_request.query, last_request.process);
      }, delay);
    };

    return {
      handle: function (query, callback) {
        queued_requests.push({ query: query, process: callback });
        startTimer();
      },
    };
  })();
};

AS.prefixed_cookie = function (cookie_name, value) {
  var args = Array.prototype.slice.call(arguments, 0);
  args[0] = COOKIE_PREFIX + '_' + args[0];
  args.push({ path: '/;SameSite=Lax', secure: location.protocol === 'https:' });
  return $.cookie.apply(this, args);
};

// Sub Record Sorting
AS.initSubRecordSorting = function ($list) {
  var $subform = $list.closest('.subrecord-form');
  if (
    $subform.data('cardinality') === 'zero_to_one' ||
    $subform.data('sorting') === 'disabled'
  ) {
    // nothing to do here
    return;
  }

  if ($list.length) {
    $list.children('li').each(function () {
      var $child = $(this);
      if (!$child.hasClass('sort-enabled')) {
        // Manually duplicate frontend/app/views/shared/_fa_grip_svg.html.erb here
        // instead of renaming this file .erb
        const fa_grip_svg = `
<svg xmlns="http://www.w3.org/2000/svg" class="fa-grip" height="16" width="10" viewBox="0 0 320 512"><path d="M40 352l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0c-22.1 0-40-17.9-40-40l0-48c0-22.1 17.9-40 40-40zm192 0l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0c-22.1 0-40-17.9-40-40l0-48c0-22.1 17.9-40 40-40zM40 320c-22.1 0-40-17.9-40-40l0-48c0-22.1 17.9-40 40-40l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0zM232 192l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0c-22.1 0-40-17.9-40-40l0-48c0-22.1 17.9-40 40-40zM40 160c-22.1 0-40-17.9-40-40L0 72C0 49.9 17.9 32 40 32l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0zM232 32l48 0c22.1 0 40 17.9 40 40l0 48c0 22.1-17.9 40-40 40l-48 0c-22.1 0-40-17.9-40-40l0-48c0-22.1 17.9-40 40-40z"/></svg>
`;
        var $handle = $(`<div class='drag-handle'>${fa_grip_svg}</div>`);
        if ($list.parent().hasClass('controls')) {
          $handle.addClass('inline');
        }
        $(this).append($handle);
        $(this).addClass('sort-enabled');
      }
    });

    if ($list.data('sortable')) {
      $list.sortable('destroy');
    }

    $list.sortable({
      items: 'li',
      handle: ' > .drag-handle',
      forcePlaceholderSize: true,
      forceHelperSize: true,
      placeholder: 'sortable-placeholder',
      tolerance: 'pointer',
      helper: 'clone',
    });

    $list.off('sortupdate').on('sortupdate', function () {
      $('form.aspace-record-form').triggerHandler('formchanged.aspace');
    });

    // ANW-429: trigger special event for agents merge form
    $list.off('sortupdate').on('sortupdate', function () {
      $($list).triggerHandler('mergesubformchanged.aspace');
    });
  }
};

// Add confirmation btn behaviour
$(function () {
  $.fn.initConfirmationAction = function () {
    $(this).each(function () {
      var $this = $(this);

      if ($this.hasClass('initialised')) {
        return;
      }

      $this.addClass('initialised');

      var template_data = {
        message: $this.data('message') || '',
        title: $this.data('title') || 'Are you sure?',
        confirm_label: $this.data('confirm-btn-label') || false,
        confirm_class: $this.data('confirm-btn-class') || false,
      };

      var onClick = function (event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        AS.openCustomModal(
          'confirmChangesModal',
          template_data.title,
          AS.renderTemplate('confirmation_modal_template', template_data),
          null,
          {},
          $this
        );
        $('#confirmButton', '#confirmChangesModal').click(function () {
          $('.btn', '#confirmChangesModal').attr('disabled', 'disabled');

          var $form = $('<form>')
            .attr('action', $this.data('target') || $this.attr('href'))
            .attr('accept-charset', 'UTF-8')
            .attr('method', $this.data('method') || 'post');

          if ($this.data('authenticity_token')) {
            var $h = $("<input type='hidden'>");
            $h.attr('name', 'authenticity_token').val(
              $this.data('authenticity_token')
            );
            $form.append($h);
          }

          if ($this.data('form-data')) {
            $.each($this.data('form-data'), function (name, value) {
              if (typeof value === 'object') {
                $.each(value, function (i, val) {
                  var $h = $("<input type='hidden'>");
                  $h.attr('name', name + '[]').val(val);
                  $form.append($h);
                });
              } else {
                var $h = $("<input type='hidden'>");
                $h.attr('name', name).val(value);
                $form.append($h);
              }
            });
          }

          $(document.body).append($form);

          $form.submit();
        });
      };

      $this.click(onClick);
    });
  };

  $(document).ready(function () {
    $(document).bind('loadedrecordform.aspace', function (event, $container) {
      $(
        '.btn[data-confirmation]:not(.initialised)',
        $container
      ).initConfirmationAction();
    });

    $('.btn[data-confirmation]:not(.initialised)').initConfirmationAction();
  });
});

// Set up some subrecord specific event bindings
$(document).bind(
  'subrecordcreated.aspace',
  function (event, object_name, newFormEl) {
    newFormEl
      .parents('.subrecord-form:first')
      .triggerHandler('subrecordcreated.aspace');
  }
);
$(document).bind('subrecorddeleted.aspace', function (event, formEl) {
  formEl.triggerHandler('subrecorddeleted.aspace');
});

// Global AJAX setup
$(function () {
  $.ajaxSetup({
    beforeSend: function (xhr, settings) {
      // if it's a POST, lets make sure the CSRF token is passed through
      if (settings.type === 'POST') {
        xhr.setRequestHeader(
          'X-CSRF-Token',
          $('meta[name="csrf-token"]').attr('content')
        );
      }
    },
  });
});

// Add close action to all alerts
$(function () {
  var handleCloseAlert = function (event) {
    event.stopPropagation();
    event.preventDefault();

    var $hideAlert = $(this);

    $hideAlert
      .hide()
      .closest('.alert')
      .slideUp(function () {
        $hideAlert.show();
      });
  };

  $.fn.initCloseAlertAction = function (event, $container) {
    $(this).each(function () {
      var $alert = $(this);

      // add a close icon to the alert
      var $close = $('<a>')
        .attr('href', 'javascript:void(0);')
        .addClass('hide-alert');
      $close.attr('aria-label', 'Close Alert');
      $close.append($('<span>').addClass('glyphicon glyphicon-remove'));
      $close.click(handleCloseAlert);

      $alert.prepend($close);
      $alert.addClass('with-hide-alert');
    });
  };

  $(document).ready(function () {
    $(document).bind('loadedrecordform.aspace', function (event, $container) {
      $('.alert', $container).initCloseAlertAction();
    });

    $('.alert:not(.with-hide-alert)').initCloseAlertAction();
  });
});

// shortcuts
$(function () {
  var initFormShortcuts = function () {
    var $form = $(this);
  };

  $(document).bind('keydown', 'shift+/', function () {
    if (!$('#ASModal').length) {
      AS.openAjaxModal(AS.app_prefix('shortcuts'));
    }
  });

  $(document).bind('keydown', 'esc', function () {
    if ($('#ASModal').length) {
      $('#ASModal').modal('hide').data('bs.modal', null);
    }
  });

  $(document).bind('keydown', 'ctrl+x', function () {
    $(document).trigger('formclosed.aspace');
  });

  $(document).bind('keydown', 'shift+b', function () {
    $('li.browse-container a.dropdown-toggle').trigger('click.bs.dropdown');
  });

  $(document).bind('keydown', 'shift+c', function () {
    $('li.create-container a.dropdown-toggle').trigger('click.bs.dropdown');
  });

  $(window).bind('keydown', function (event) {
    if (event.ctrlKey || event.metaKey) {
      switch (String.fromCharCode(event.which).toLowerCase()) {
        case 's':
          event.preventDefault();
          break;
      }
    }
  });

  var traverseMenuDown = function () {
    var $current = $(this).find('ul li.active');
    var $next = $current.length ? $current.next() : $(this).find('li:first');

    if ($next.length) {
      $next.addClass('active');
      $current.removeClass('active');
    }
  };

  var traverseMenuUp = function () {
    var $current = $(this).find('ul li.active');
    var $next = $current.length ? $current.prev() : $(this).find('li:last');

    if ($next.length) {
      $next.addClass('active');
      $current.removeClass('active');
    }
  };

  var clickActive = function (e) {
    e.preventDefault();
    e.stopPropagation();
    var $active = $(this).find('ul li.active');
    if ($active.length) {
      $active.find('a:first')[0].click();
    }
  };

  $('li.dropdown').on({
    'shown.bs.dropdown': function () {
      $(this).bind('keydown', 'down', traverseMenuDown);
      $(this).bind('keydown', 'up', traverseMenuUp);
      $(this).bind('keydown', 'return', clickActive);
    },
    'hide.bs.dropdown': function () {
      $(this).unbind('keydown', traverseMenuDown);
      $(this).unbind('keydown', traverseMenuUp);
      $(this).unbind('keydown', clickActive);
    },
  });
});

AS.app_prefix = function (path) {
  return APP_PATH + path.replace(/^\//, '');
};

// Enable bootstrap-tagsinput for any elements with class 'js-taggable'
$(function () {
  $(document).ready(function () {
    $('.js-taggable').tagsinput({ confirmKeys: [13], delimiter: '|' });
  });
});
