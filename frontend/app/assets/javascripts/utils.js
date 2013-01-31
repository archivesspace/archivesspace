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
  var bindSidebarEvents = function() {
    $("#archivesSpaceSidebar .nav-list").on("click", "a", function(event) {
      event.preventDefault();
      event.stopPropagation();

      var $target_item = $(this);
      $($target_item.attr("href")).ScrollTo({
        callback: function() {
            $(".active", "#archivesSpaceSidebar").removeClass("active");
            $target_item.parents("li:first").addClass("active");
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
      $(this).addClass("initialised");
    });
  };

  initSidebar();

  $(document).ajaxComplete(function() {
    initSidebar();
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
  $(document).bind("new.subrecord init.subrecord", function(event, object_name, subform) {
    initDateFields(subform)
  });
});


// any element with a popover!
$(function() {
  var initPopovers = function(scope) {
    scope = scope || $(document.body);
    $(".has-popover:not(.initialised)", scope)
      .popover()
      .click(function(e) {
        e.preventDefault()
      }).addClass("initialised");
  };
  initPopovers();
  $(document).ajaxComplete(function() {
    initPopovers();
  });
  $(document).bind("new.subrecord init.subrecord init.popovers", function(event, object_name, subform) {
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
      if ($this.data("trigger") === "manual" && $this.is("label.control-label")) {
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
  $(document).bind("new.subrecord init.subrecord init.tooltips", function(event, object_name, subform) {
    initTooltips(subform)
  });
});


// allow click of a submenu link
$(function() {
  var initSubmenuLink = function(scope) {
    scope = scope || $(document.body);
    $(".dropdown-submenu > a:not(.initialised)", scope).click(function(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      $(this).focus();
    }).addClass("initialised");
  };
  initSubmenuLink();
  $(document).ajaxComplete(function() {
    initSubmenuLink();
  });
  $(document).bind("new.subrecord init.subrecord init.popovers", function(event, object_name, subform) {
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


AS.openCustomModal = function(id, title, contents) {
  $("body").append(AS.renderTemplate("modal_custom_template", {id:id,title:title,content: ""}));
  $("#"+id).append(contents).on("hidden", function() {
    $(this).remove();
  }).modal('show');
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

// add control-group :input focus/blur behaviour
//$(function() {
//  $(document).ready(function() {
//    AS.addControlGroupHighlighting($(document.body))
//  });
//});

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
  });

  $(".confirm-removal", confirmationEl).click(function(event) {
    event.preventDefault();
    event.stopPropagation();
    onConfirmCallback($(event.target));
  });
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

// Sub Record Sorting
AS.initSubRecordSorting = function($list) {
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
    $list.sortable('destroy').sortable({
      items: 'li',
      handle: ' > .drag-handle',
      forcePlaceholderSize: true
    });
    $list.off("sortupdate").on("sortupdate", function() {
      $("#object_container form").triggerHandler("form-changed");
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

      var confirmInlineFormAction = function() {
        $this.parents("form").submit();
      };


      var confirmCustomAction = function() {
        $.ajax({
          url: $this.data("target"),
          data: $this.data("params"),
          type: $this.data("method"),
          complete: function() {
            $("#confirmChangesModal").modal("hide").remove();
            if ($this.data("refresh")) {
              document.location.reload;
            }
          }
        });
      };

      var onClick = function(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        AS.openCustomModal("confirmChangesModal", template_data.title , AS.renderTemplate("confirmation_modal_template", template_data));
        $("#confirmButton", "#confirmChangesModal").click(function() {
          if ($this.parents(".btn-inline-form:first").length) {
            confirmInlineFormAction();
          } else {
            confirmCustomAction
          }
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