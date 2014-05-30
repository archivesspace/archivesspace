$(function() {
  AS.mixedContentElements = {
      "blockquote": {
        "tag": "blockquote",
        "attributes": [],
        "exclude": ["abstract"]
      },
      "date": {
        "tag": "date",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "function": {
        "tag": "function",
        "attributes": ["rules", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "occupation": {
        "tag": "occupation",
        "attributes": ["type", "normal", "calendar", "era"], 
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "subject": {
        "tag": "subject",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "emph": {
        "tag": "emph",
        "attributes": ["render"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "corpname": {
        "tag": "corpname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      },
      "p": {
        "tag": "p",
        "attributes": [],
        "elements": ["emph"],
        "exclude": ["abstract"]
      },
      "persname": {
        "tag": "persname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]

      },
      "famname": {
        "tag": "famname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]

      },
      "name": {
        "tag": "name",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]

      },
      "geogname": {
        "tag": "geogname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]

      },
      "genreform": {
        "tag": "genreform",
        "attributes": ["rules", "role", "type"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]

      },
      "title": {
        "tag": "title",
        "attributes": ["render", "accurals"],
        "exclude": ["appraisal", "arrangement", "bioghist", "accessrestrict"]
      },
      "ref": {
        "tag": "ref",
        "attributes": ["target", "show", "title", "actuate", "href"],
        "exclude": [ "accurals", "appraisal", "arrangement", "bioghist", "accessrestrict"]
      },
      "extref": {
        "tag": "extref",
        "attributes": ["show", "title", "actuate", "href"],
        "exclude": ["abstract", "accurals", "appraisal", "arrangement", "bioghist", "accessrestrict"]

      },
      "lb": {
        "tag": "lb",
        "attributes": [],
        "exclude": [ "accurals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict"]
      }
    };
});
