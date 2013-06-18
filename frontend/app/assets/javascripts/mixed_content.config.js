$(function() {
  AS.mixedContentElements = {
      "blockquote": {
        "tag": "blockquote",
        "attributes": []
      },
      "date": {
        "tag": "date",
        "attributes": ["type", "normal", "calendar", "era"]
      },
      "function": {
        "tag": "function",
        "attributes": ["rules", "source"]
      },
      "occupation": {
        "tag": "occupation",
        "attributes": ["type", "normal", "calendar", "era"]
      },
      "subject": {
        "tag": "subject",
        "attributes": ["type", "normal", "calendar", "era"]
      },
      "emph": {
        "tag": "emph",
        "attributes": ["render"]
      },
      "corpname": {
        "tag": "corpname",
        "attributes": ["rules", "role", "source"]
      },
      "p": {
        "tag": "p",
        "attributes": [],
        "elements": ["emph"]
      },
      "persname": {
        "tag": "persname",
        "attributes": ["rules", "role", "source"]
      },
      "famname": {
        "tag": "famname",
        "attributes": ["rules", "role", "source"]
      },
      "name": {
        "tag": "name",
        "attributes": ["rules", "role", "source"]
      },
      "geogname": {
        "tag": "geogname",
        "attributes": ["rules", "role", "source"]
      },
      "genreform": {
        "tag": "genreform",
        "attributes": ["rules", "role", "type"]
      },
      "title": {
        "tag": "title",
        "attributes": ["render"]
      },
      "ref": {
        "tag": "ref",
        "attributes": ["target", "show", "title", "actuate"]
      },
      "extref": {
        "tag": "extref",
        "attributes": ["target", "show", "title", "actuate"]
      },
      "lb": {
        "tag": "lb",
        "attributes": []
      }
    };
});
