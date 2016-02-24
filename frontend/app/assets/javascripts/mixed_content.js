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

      var noteTypes = generateNoteTypes($this);  
      var tagList = generateTagWhitelist(noteTypes);

      var $wrapWithAction = $(AS.renderTemplate("mixed_content_wrap_action_template", {tags: tagList}));
      var $wrapWithActionSelect = $("select", $wrapWithAction);

      var $editor = CodeMirror.fromTextArea($this[0], {
        value: $this.val(),
        
        onFocus: function() {  
            // we need to check to see if the values have been changed.   
            noteTypes = generateNoteTypes($this);  
            tagList = generateTagWhitelist(noteTypes);
            generateXMLHints(tagList);
                 
            $wrapWithActionSelect.empty();     

            $.each(tagList, function(tag, def) {
                $wrapWithActionSelect.append("<option>" + tag + "</option>");                 
            }); 
        }, 
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
      $this.addClass("initialised");

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


  var generateNoteTypes = function(inputBox) {
      var noteTypes = inputBox.closest('.mixed-content-anchor > ul > li').find("[class$=-type]" ).map(function() {
                                return this.value;
                        }).get();
      return noteTypes; 
  }


  // We need to filter out some tags to not be included in certain note types
  var generateTagWhitelist = function(noteTypes) {
    noteTypes = (typeof noteTypes === "undefined") ? [] : noteTypes;
    whitelist = {};
    if (AS.mixedContentElements) {
      $.each(AS.mixedContentElements, function(tag, def) {
        var exclude = false;
        // check if the definition has the noteType in its exclude list 
        if ( def.exclude ) {
          exclude = ( $(def.exclude).filter(noteTypes).length > 0 ); 
        }
        // if not, add it to the whitelist 
        if ( !exclude ) { 
          whitelist[tag]  = def;
        }
      });
    };
    return whitelist;
  }
 
  var generateXMLHints = function(tagList) {
    var addToPath = function(path, defs) {
      
      CodeMirror.xmlHints[path] = [];

      for (var i=0; i<defs.length; i++ ) {
        var definition = defs[i];

        if (typeof definition == "string") {
          definition = AS.mixedContentElements[definition];
        }

        CodeMirror.xmlHints[path].push(definition.tag);
        CodeMirror.xmlHints[path + definition.tag + " "] = definition.attributes || [];

        if (definition.elements) {
          addToPath(path+definition.tag+"><", definition.elements);
        }
      }

    };


    tagList = (typeof tagList === "undefined") ? {} : tagList;
    
    if (tagList) {
      CodeMirror.xmlHints['<'] = [];
      $.each(tagList, function(tag, def) {
          CodeMirror.xmlHints['<'].push(tag);
          CodeMirror.xmlHints["<" + tag + " "] = def.attributes || [];
          if (def.elements  ) {
            addToPath("<" + def.tag + "><", def.elements);
          }
      });
    } else {
      throw "No mixed content rules found: AS.mixedContentElements is null"
    }
  };

  generateXMLHints();


  $(document).bind("subrecordcreated.aspace", function(event, object_name, subform) {
    $("textarea.mixed-content:not(.initialised)", subform).mixedContent();
  });

  $(document).bind("expandcontainer.aspace", function(event, $container) {
    $("textarea.mixed-content:not(.initialised)", $container).mixedContent();
  });

  // $("textarea.mixed-content:not(.initialised)").mixedContent();
});

