//= require codemirror/codemirror.js
//= require codemirror/util/simple-hint.js
//= require codemirror/util/closetag.js
//= require codemirror/util/xml-hint.js
//= require codemirror/mode/xml/xml.js
//= require mixed_content.config.js

$(function() {
  $.fn.mixedContent = function() {
    $(this).each(function() {
      var $this = $(this);

      if ($this.hasClass("initialised")) {
        return;
      }

      var selected;

      $this.addClass("initialised");

      var $wrapWithAction = $(AS.renderTemplate("mixed_content_wrap_action_template", {tags: AS.mixedContentElements}));
      var $wrapWithActionSelect = $("select", $wrapWithAction);

      var $editor = CodeMirror.fromTextArea($this[0], {
        value: $this.val(),
        mode: 'text/html',
        smartIndent: false,
        extraKeys: {
          "'>'": function(cm) { cm.closeTag(cm, '>'); },
          "'/'": function(cm) { cm.closeTag(cm, '/'); },
          "' '": function(cm) { CodeMirror.xmlHint(cm, ' '); },
          "'<'": function(cm) { CodeMirror.xmlHint(cm, '<'); },
          "Ctrl-Space": function(cm) { CodeMirror.xmlHint(cm, ''); }
        },
        lineWrapping: true,
        onCursorActivity: function(cm) {
          if (cm.somethingSelected()) {
            var coords_start = $editor.cursorCoords(true, "local");
            var coords_end = $editor.cursorCoords(false, "local");

            var top_offset = $wrapWithAction.height() - 20 + coords_end.y;
            var left_offset = Math.min(
                                coords_start.y == coords_end.y ? coords_start.x : coords_end.x,
                                $($editor.getWrapperElement()).width() - $wrapWithAction.width()
                              );

            $wrapWithAction
              .css("top", top_offset + "px")
              .css("left", left_offset+"px")
              .css("position", "absolute");
            $wrapWithAction.show();
          } else {
            $wrapWithActionSelect.val("");
            $wrapWithAction.hide();
            $editor.save();
          }
        }
      });

      $this.data("CodeMirror", $editor);

      var onWrapActionChange = function(event) {
        if ($editor.somethingSelected() && $wrapWithActionSelect.val() != "") {
          var tag = $wrapWithActionSelect.val();
          $editor.replaceSelection("<"+tag+">"+$editor.getSelection()+"</"+tag+">");
          var cursorPosition = $editor.getCursor();
          $editor.setCursor({
            line: cursorPosition.line,
            ch: $editor.getSelection() + cursorPosition.ch
          });
          $editor.focus();
        }
      };

      $wrapWithAction.bind("change", onWrapActionChange);
      $($editor.getWrapperElement()).append($wrapWithAction).append(AS.renderTemplate("mixed_content_help_template"));
    });
  };

  var generateXMLHints = function() {
    var addToPath = function(path, defs) {
      
      CodeMirror.xmlHints[path] = [];

      for (var i=0; i<defs.length; i++ ) {
        CodeMirror.xmlHints[path].push(defs[i].tag);

        if (defs[i].elements) {
          addToPath(path+defs[i].tag+"><", defs[i].elements);
        }
      }

    };

    if (AS.mixedContentElements) {
      CodeMirror.xmlHints['<'] = [];
      for (var i = 0; i < AS.mixedContentElements.length; i++) {
        var def = AS.mixedContentElements[i];

        CodeMirror.xmlHints['<'].push(def.tag);
        CodeMirror.xmlHints["<" + def.tag + " "] = def.attributes || [];

        if (def.elements) {
          addToPath("<" + def.tag + "><", def.elements)
        }

        
      }
    } else {
      throw "No mixed content rules found: AS.mixedContentElements is null"
    }
  };

  generateXMLHints();

  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    $("textarea.mixed-content:not(.initialised)", subform).mixedContent();
  });

  $(document).ajaxComplete(function() {
    $("textarea.mixed-content:not(.initialised)").mixedContent();
  });

  $("textarea.mixed-content:not(.initialised)").mixedContent();
});

