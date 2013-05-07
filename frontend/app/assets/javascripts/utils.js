//= require trimpath-template-1.0.38
//= require bootstrap-datepicker

// initialise ajax modal

$(function() {
  var openAjaxModal = function(href) {
    $("body").append('<div class="modal hide" id="tempAjaxModal"></div>');
    $("#tempAjaxModal").load(href, function() {
      $("#tempAjaxModal").on("shown",function() {
        $(this).find("input[type!=hidden]:first").focus();
      }).on("hidden", function() {
        $(this).remove();
      }).modal('show');
    });
  };

  $("body").on("click", "[data-toggle=modal-ajax]", function(e) {
    e.preventDefault();
    openAjaxModal($(this).attr("href"));     
  });
});


// add four part indentifier behaviour
$(function() {
  var initIdentifierFields = function() {
    $("form:not(.navbar-form) .identifier-fields:not(.initialised)").on("keyup", ":input", function(event) {
      $(this).addClass("initialised");
      var currentInputIndex = $(event.target).index();
      $(event.target).parents(".identifier-fields:first").find(":input:eq("+(currentInputIndex+1)+")").each(function() {
        if ($(event.target).val().length === 0 && $(this).val().length === 0) {
          $(this).attr("disabled", "disabled");
        } else {
          $(this).removeAttr("disabled");
        }
      });
    });
  }
  $(document).ajaxComplete(function() {
    initIdentifierFields();
  });
  initIdentifierFields();
});


// sidebar action
$(function() {
  var getSubMenuHTML = function() {
    return $("<ul class='nav-list-submenu'></ul>");
  };

  var getSubMenuItemHTML = function(anItem) {
    var $li = $("<li>");
    var $link = $("<a>");
    $link.addClass("nav-list-submenu-link");
    $link.attr("href", "javascript:void(0);");
    if ($(".error", anItem).length > 0) {
      $link.addClass("has-errors");
    }
    $li.append($link);
    return $li;
  };

  var refreshSidebarSubMenus = function() {
    if ($(".readonly-context:first").length > 0) {
      // this could be a read only page... so don't
      // show the sub record bits
      return;
    }
    $(".nav-list-submenu").empty();
    $("#archivesSpaceSidebar .nav-list > li").each(function() {
      var $nav = $(this);
      var $link = $("a", $nav);
      var $section = $($link.attr("href"));
      var $items = $(".subrecord-form-list:first > li", $section);

      var $submenu = getSubMenuHTML();
      //if ($items.length > 1) {
        for (var i=0; i<$items.length; i++) {
          $submenu.append(getSubMenuItemHTML($items[i]));
        }
        $link.append($submenu);
      //}
    });
  };

  var bindSidebarEvents = function() {
    $("#archivesSpaceSidebar .nav-list").on("click", "> li > a", function(event) {
      event.preventDefault();
      event.stopPropagation();

      var $target_item = $(this);
      $($target_item.attr("href")).ScrollTo({
        callback: function() {
          $(".active", "#archivesSpaceSidebar").removeClass("active");
          var $active = $target_item.parents("li:first");
          $active.addClass("active");
        }
      });
    });
  };

   var initSidebar = function() {
    $("#archivesSpaceSidebar .nav-list:not(.initialised)").each(function() {
      $.proxy(bindSidebarEvents, this)();
      $(this).affix({
        offset: {
          top: function() {
            return $("#archivesSpaceSidebar").offset().top;
          },
          bottom: 100
        }
      });

      $(this).on("click", ".nav-list-submenu-link", function(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        var $this = $(this);

        var $section = $($this.parent().closest("a").attr("href"));
        var $target = $($(".subrecord-form-list:first > li", $section)[$this.parent().index()]);
        $target.ScrollTo({
          callback: function() {
            $(".active", "#archivesSpaceSidebar").removeClass("active");
            $this.parent().parent().closest("li").addClass("active");
          }
        });
      });

      $(this).addClass("initialised");
    });
    refreshSidebarSubMenus();
  };

  initSidebar();

  $(document).ajaxComplete(function() {
    initSidebar();
  });

  $(document).bind("subrecordcreated.aspace subrecorddeleted.aspace formErrorsReady", function() {
    if ($("#archivesSpaceSidebar .nav-list.initialised").length > 0) {
      refreshSidebarSubMenus();
      // refresh scrollspy offsets.. as they are probably wrong now that things have changed in the form
      $('[data-spy="scroll"]').scrollspy('refresh');
    }
  });
  $(document).bind("resize.tree", function() {
    // refresh scrollspy offsets.. as they are probably wrong now that things have changed in the form
    $('[data-spy="scroll"]').scrollspy('refresh');
  });

});

// date fields and datepicker initialisation
$(function() {
  var initDateFields = function(scope) {
    scope = scope || $(document.body);
    $(".date-field:not(.initialised)", scope).each(function() {
      $(this).addClass("initialised");
      $(this).datepicker({
        autoclose: true
      });
    });
  };
  initDateFields();
  $(document).ajaxComplete(function() {
    initDateFields();
  });
  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    initDateFields(subform)
  });
});


// any element with a popover!
$(function() {
  var popoverOptions = {
    delay: {show: 0, hide: 200} // if the popover contains a link, allow a few moments for that click to count
  };

  var initPopovers = function(scope) {
    scope = scope || $(document.body);
    $(".has-popover:not(.initialised)", scope)
      .popover(popoverOptions) 
      .click(function(e) {
        e.preventDefault()
      }).addClass("initialised");
  };
  initPopovers();
  $(document).ajaxComplete(function() {
    initPopovers();
  });
  $(document).bind("subrecordcreated.aspace init.popovers", function(event, object_name, subform) {
    initPopovers(subform)
  });
});


// any element with a tooltip!
$(function() {
  var initTooltips = function(scope) {
    scope = scope || $(document.body);
    $(".has-tooltip:not(.initialised)", scope).each(function() {
      var $this = $(this);
      $this.tooltip().addClass("initialised");

      // for manual ArchiveSpace help tooltips
      if ($this.data("trigger") === "manual" && ($this.is("label.control-label") || $this.is(".subrecord-form-heading-label"))) {
        var openedViaClick = false;
        var showTimeout, hideTimeout;

        var onMouseEnter = function() {
          if (openedViaClick) return;

          clearTimeout(hideTimeout);
          showTimeout = setTimeout(function() {
            showTimeout = null;
            $this.tooltip("show");
          }, $this.data("delay") || 500);
          $this.off("mouseleave").on("mouseleave", onMouseLeave);
        };

        var onMouseLeave = function() {
          if (showTimeout) {
            clearTimeout(showTimeout);
          } else {
            hideTimeout = setTimeout(function() {
              $this.tooltip("hide");
            }, 100);
          }
        };

        var onClick = function() {
          clearTimeout(showTimeout);

          if (openedViaClick) {
            $this.tooltip("hide");
            openedViaClick = false;
            return;
          }

          $this.off("mouseleave");

          $this.tooltip("show");
          $(".tooltip-inner", $this.data("tooltip").$tip).prepend('<span class="tooltip-close icon-remove-circle icon-white"></span>');
          $(".tooltip-close", $this.data("tooltip").$tip).click(function() {
            $this.trigger("click");
          });
          openedViaClick = true;
        }

        // bind event callbacks
        $this.bind("mouseenter", onMouseEnter).click(onClick);
      }
    });
  };
  initTooltips();
  $(document).ajaxComplete(function() {
    initTooltips();
  });
  $(document).bind("subrecordcreated.aspace init.tooltips", function(event, object_name, subform) {
    initTooltips(subform)
  });
});


// allow click of a submenu link
$(function() {
  var initSubmenuLink = function(scope) {
    scope = scope || $(document.body);
    $(".dropdown-submenu > a[href*='javascript:void']:not(.initialised)", scope).click(function(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      $(this).focus();
    }).addClass("initialised");
  };
  initSubmenuLink();
  $(document).ajaxComplete(function() {
    initSubmenuLink();
  });
  $(document).bind("subrecordcreated.aspace init.popovers", function(event, object_name, subform) {
    initSubmenuLink(subform)
  });
});


var AS = {};


AS.templateCache = [];
AS.renderTemplate = function(templateId, data) {
  if (!AS.templateCache[templateId]) {
    var templateNode = $("#"+templateId).get(0);
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
      AS.templateCache[templateId] = TrimPath.parseTemplate(template, templateId);
    }
  }
  return AS.templateCache[templateId].process(data);
};


AS.quickTemplate = function(templateHTML, data) {
  return TrimPath.parseTemplate(templateHTML).process(data);
};


AS.encodeForAttribute = function(string) {
  if (string === null || string === undefined) {
    return "";
  }
  return string.replace(/"/g, "&quot;");
};


AS.openCustomModal = function(id, title, contents, fillScreen) {
  $("body").append(AS.renderTemplate("modal_custom_template", {id:id,title:title,content: "", fill: fillScreen||false}));
  var $modal = $("#"+id);
  $modal.append(contents);
  $modal.on("hidden", function() {
    $modal.remove();
    $(window).unbind("resize", resizeModal);
  });

  var resizeModal = function() {
    $modal.height($(window).height() - ($(window).height() * 0.2)); // -20% for 10% top and bottom margins
    var modalBodyHeight = $modal.height() - $(".modal-header", $modal).height() - $(".modal-footer", $modal).height() - 80;
    $(".modal-body", $modal).height(modalBodyHeight);
    $modal.css("marginLeft", -$modal.width() / 2);
  }

  if (fillScreen) {
    $modal.on("shown resize", resizeModal);
    $(window).resize(resizeModal);
  }

  $modal.modal('show');
};


$.fn.serializeObject = function() {
    var o = {};

    if ($(this).is("form")) {
      var a = this.serializeArray();
      $.each(a, function() {
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
      $(":input", this).each(function() {
        o[this.name] = $(this).val();
      });
    }

    return o;
};

$.fn.setValuesFromObject = function(obj) {
  // NOTE: THIS DOESN'T WORK FOR RADIO ELEMENTS (YET)
  var $this = this;
  $.each(obj, function(name, value) {
    $("[name='"+name+"']", $this).val(value);
  });
}


AS.addControlGroupHighlighting = function(parent) {
  $(".control-group :input", parent).on("focus", function() {
    $(this).parents(".control-group:first").addClass("active");
  }).on("blur", function() {
    $(this).parents(".control-group:first").removeClass("active");
  });
};


// confirmation behaviour for subform-remove actions
AS.confirmSubFormDelete = function(subformRemoveButtonEl, onConfirmCallback) {

  // Hide any others that were selected first
  $(".cancel-removal:visible").trigger('click');

  var confirmationEl = $(AS.renderTemplate("subform_remove_confirmation_template"));
  confirmationEl.hide();
  subformRemoveButtonEl.hide();
  subformRemoveButtonEl.before(confirmationEl);
  confirmationEl.fadeIn();
  $(".confirm-removal", confirmationEl).focus();

  $(".cancel-removal", confirmationEl).click(function(event) {
    confirmationEl.remove();
    subformRemoveButtonEl.fadeIn();
    return false;
  });

  $(".confirm-removal", confirmationEl).click(function(event) {
    event.preventDefault();
    event.stopPropagation();
    onConfirmCallback($(event.target));
    return false;
  });

  return false;
};

// extra add button plugin for subrecord forms
AS.initAddAsYouGoActions = function($form, $list) {
  if ($form.data("cardinality") === "zero_to_one") {
    // nothing to do here
    return;
  }

  // delete any existing subrecord-add-as-you-go-actions
  $(".subrecord-add-as-you-go-actions", $form).remove();

  var $asYouGo = $("<div class='subrecord-add-as-you-go-actions'></div>");
  $form.append($asYouGo);

  var numberOfSubRecords = function() {
    return $("> li", $list).length;
  };

  var bindEvents = function() {
    $form.off("subrecordcreated.aspace").on("subrecordcreated.aspace", function() {
      $asYouGo.fadeIn()
    });

    $form.off("subrecorddeleted.aspace").on("subrecorddeleted.aspace", function() {
      if (numberOfSubRecords() === 0) {
        $asYouGo.hide()
      }
    });
  }

  var init = function() {
    if (numberOfSubRecords() === 0) {
      $asYouGo.hide();
    }

    var btnsToReplicate = $(".subrecord-form-heading:first > .btn, .subrecord-form-heading:first > .custom-action > .btn", $form);
    var fillToPercentage = 100; // full width

    btnsToReplicate.each(function() {
      var $btn = $(this);
      var $a = $("<a href='#'>+</a>");
      var btnText = $btn.val().length ? $btn.val() : $btn.text();
      $a.css("width", Math.floor(fillToPercentage / btnsToReplicate.length) + "%");

      if (btnsToReplicate.length > 1) {
        // we need to differentiate the links
        $a.text(btnText);
        $a.addClass("has-label");
      } else {
        // just add a title and we'll have a '+'
        $a.attr("title", btnText);
      }

      $a.click(function(e) {
        e.preventDefault();

        $btn.triggerHandler("click");
      });
      $asYouGo.append($a);
    });

    bindEvents();
  }

  init();
};


// Used by all tree layouts -- sets the initial height for the tree pane... but can
// be overridden by a user's cookie value
AS.DEFAULT_TREE_PANE_HEIGHT = 100;

AS.resetScrollSpy = function() {
  // reset the scrollspy plugin
  // so the headers update the status of the sidebar
  $(document.body).removeData("scrollspy");
  $(document.body).scrollspy({
    target: "#archivesSpaceSidebar",
    offset: 20
  });
}

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
        queued_requests.push({query: query, process: callback});
        startTimer();
      }
    };
  }());
};



// Sub Record Sorting
AS.initSubRecordSorting = function($list) {
  var $subform = $list.closest(".subrecord-form");
  if ($subform.data("cardinality") === "zero_to_one"
        || $subform.data("sorting") === "disabled") {
    // nothing to do here
    return;
  }

  if ($list.length) {
    $list.children("li").each(function() {
      var $child = $(this);
      if (!$child.hasClass("sort-enabled")) {
        var $handle = $("<div class='drag-handle'></div>");
        if ($list.parent().hasClass("controls")) {
          $handle.addClass("inline");
        }
        $(this).append($handle);
        $(this).addClass("sort-enabled");
      }
    });

    if ($list.data("sortable")) {
      $list.sortable("destroy");
    }

    $list.sortable({
      items: 'li',
      handle: ' > .drag-handle',
      forcePlaceholderSize: true,
      forceHelperSize: true,
      placeholder: "sortable-placeholder",
      tolerance: "pointer",
      helper: "clone"
    });

    $list.off("sortupdate").on("sortupdate", function() {
      $("#object_container form").triggerHandler("formchanged.aspace");
    });
  }
}

// Add confirmation btn behaviour
$(function() {
  $.fn.initConfirmationAction = function() {
    $(this).each(function() {

      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      $this.addClass("initialised");

      var template_data = {
        message: $this.data("message") || "",
        title: $this.data("title") || "Are you sure?",
        confirm_label: $this.data("confirm-btn-label") || false,
        confirm_class: $this.data("confirm-btn-class") || false
      };

      var confirmAction = function() {
        $.ajax({
          url: $this.data("target") || $this.attr("href"),
          data: $this.data("params"),
          type: $this.data("method"),
          dataType: $this.data("dataType") || "html",
          success: function(result) {
            if ($this.data("dataType") === "json") {
              var msg = $("<div class='alert-success alert'>");
              msg.html(result['message']);
              $("#confirmChangesModal .modal-body").html(msg);
              $(".btn", "#confirmChangesModal").attr("disabled", "disabled");
              setTimeout(function() {
                document.location.href = result['redirect_to'];
              }, 500);
            } else {
              document.location.reload(true);
            }
          }
        });
      };

      var onClick = function(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        AS.openCustomModal("confirmChangesModal", template_data.title , AS.renderTemplate("confirmation_modal_template", template_data));
        $("#confirmButton", "#confirmChangesModal").click(function() {
          confirmAction();
        });
      }

      $this.click(onClick);
    })
  };

  $(document).ready(function() {
    $(document).ajaxComplete(function() {
      $(".btn[data-confirmation]:not(.initialised)").initConfirmationAction();
    });

    $(".btn[data-confirmation]:not(.initialised)").initConfirmationAction();
  });
});

// Set up some subrecord specific event bindings
$(document).bind("subrecordcreated.aspace", function(event, object_name, newFormEl) {
  newFormEl.parents(".subrecord-form:first").triggerHandler("subrecordcreated.aspace");
});
$(document).bind("subrecorddeleted.aspace", function(event, formEl) {
  formEl.triggerHandler("subrecorddeleted.aspace");
});
