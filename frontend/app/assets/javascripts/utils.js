//= require trimpath-template-1.0.38

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


// custom controls-accordion for radio driven accordion
$(function() {
  // ensure accordion is expanded for checked radios
  $(".controls-accordion input:checked").each(function() {
    $($(this).parents("label:first").attr("href")).addClass("in");
  });

  // ensure radio is checked for expanding accordion
  $(".controls-accordion label.radio").on("click", function() {
    $("input", this).attr("checked","checked");
  });
});


// add form change detection
$(function() {
  var ignoredKeycodes = [37,39,9];
  var onFormElementChange = function(event) {
    $("#object_container form").triggerHandler("form-changed");
  };
  $("#object_container form :input").live("change keyup", function(event) {
    if ($(this).data("original_value") && ($(this).data("original_value") !== $(this).val())) {
      onFormElementChange();
    } else if ($.inArray(event.keyCode, ignoredKeycodes) === -1) {
      onFormElementChange();
    }
  });
  $("#object_container form :radio, .object-container form :checkbox").live("click", onFormElementChange);
});


// add four part indentifier behaviour
$(function() {
  $("form").live("keyup", ".identifier-fields :input", function(event) {
    var currentInputIndex = $(event.target).index();
    $(event.target).parents(".identifier-fields:first").find(":input:eq("+(currentInputIndex+1)+")").each(function() {
      if ($(event.target).val().length === 0 && $(this).val().length === 0) {
        $(this).attr("disabled", "disabled");
      } else {
        $(this).removeAttr("disabled");
      }
    });
  });
});


// sidebar action
$(function() {
  $("#archivesSpaceSidebar").on("click", ".nav a", function(event) {
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


$.fn.serializeObject = function()
{
    var o = {};
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
    return o;
};


AS.addControlGroupHighlighting = function(parent) {
  $(".control-group :input", parent).on("focus", function() {
    $(this).parents(".control-group:first").addClass("active");
  }).on("blur", function() {
    $(this).parents(".control-group:first").removeClass("active");
  });
};

// add control-group :input focus/blur behaviour
$(function() {
  $(document).ready(function() {
    AS.addControlGroupHighlighting($(document.body))
  });
});