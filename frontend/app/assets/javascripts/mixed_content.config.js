$(function() {
  AS.mixedContentElements = {
      "blockquote": {
        "tag": "blockquote",
        "attributes": [],
        "exclude": ["abstract", "dimensions", "legalstatus", "langmaterial", "materialspec", "physdesc", "physfacet", "physloc"]
      },
      "date": {
        "tag": "date",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_index", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial", "langmaterial", "materialspec", "physloc"]
      },
      "function": {
        "tag": "function",
        "attributes": ["rules", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial" , "note_index", "langmaterial", "materialspec", "physloc"]
      },
      "occupation": {
        "tag": "occupation",
        "attributes": ["type", "normal", "calendar", "era"], 
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]
      },
      "subject": {
        "tag": "subject",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]
      },
      "emph": {
        "tag": "emph",
        "attributes": ["render"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index"]
      },
      "corpname": {
        "tag": "corpname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial" , "note_index", "langmaterial", "materialspec", "physloc"]
      },
      "p": {
        "tag": "p",
        "attributes": [],
        "elements": ["emph"],
        "exclude": ["abstract", "dimensions", "legalstatus", "langmaterial", "materialspec", "physdesc", "physfacet", "physloc"]
      },
      "persname": {
        "tag": "persname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]

      },
      "famname": {
        "tag": "famname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]

      },
      "name": {
        "tag": "name",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]

      },
      "geogname": {
        "tag": "geogname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]

      },
      "genreform": {
        "tag": "genreform",
        "attributes": ["rules", "role", "type"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial", "note_index", "langmaterial", "materialspec", "physloc"]

      },
      "title": {
        "tag": "title",
        "attributes": ["render", "accruals"],
        "exclude": ["appraisal", "accruals", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" , "note_index"]
      },
      "ref": {
        "tag": "ref",
        "attributes": ["target", "show", "title", "actuate", "href"],
        "exclude": [ "accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" , "note_index"]
      },
      "extref": {
        "tag": "extref",
        "attributes": ["show", "title", "actuate", "href"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" , "separatedmaterial", "note_index"]

      },
      "lb": {
        "tag": "lb",
        "attributes": [],
        "exclude": [ "accruals", "appraisal", "arrangement", "note_bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial", "note_index" , "langmaterial", "materialspec"]
      }
    };
});
