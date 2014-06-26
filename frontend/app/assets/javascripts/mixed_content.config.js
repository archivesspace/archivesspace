$(function() {
  AS.mixedContentElements = {
      "blockquote": {
        "tag": "blockquote",
        "attributes": [],
        "exclude": ["abstract", "dimensions", "legalstatus"]
      },
      "date": {
        "tag": "date",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial"]
      },
      "function": {
        "tag": "function",
        "attributes": ["rules", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial" ]
      },
      "occupation": {
        "tag": "occupation",
        "attributes": ["type", "normal", "calendar", "era"], 
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]
      },
      "subject": {
        "tag": "subject",
        "attributes": ["type", "normal", "calendar", "era"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]
      },
      "emph": {
        "tag": "emph",
        "attributes": ["render"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]
      },
      "corpname": {
        "tag": "corpname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial" ]
      },
      "p": {
        "tag": "p",
        "attributes": [],
        "elements": ["emph"],
        "exclude": ["abstract", "dimensions", "legalstatus"]
      },
      "persname": {
        "tag": "persname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]

      },
      "famname": {
        "tag": "famname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]

      },
      "name": {
        "tag": "name",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]

      },
      "geogname": {
        "tag": "geogname",
        "attributes": ["rules", "role", "source"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]

      },
      "genreform": {
        "tag": "genreform",
        "attributes": ["rules", "role", "type"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "dimensions", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent" , "separatedmaterial"]

      },
      "title": {
        "tag": "title",
        "attributes": ["render", "accruals"],
        "exclude": ["appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" ]
      },
      "ref": {
        "tag": "ref",
        "attributes": ["target", "show", "title", "actuate", "href"],
        "exclude": [ "accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" ]
      },
      "extref": {
        "tag": "extref",
        "attributes": ["show", "title", "actuate", "href"],
        "exclude": ["abstract", "accruals", "appraisal", "arrangement", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "legalstatus", "phystech", "prefercite", "processinfo", "scopecontent" , "separatedmaterial"]

      },
      "lb": {
        "tag": "lb",
        "attributes": [],
        "exclude": [ "accruals", "appraisal", "arrangement", "bibliography", "bioghist", "accessrestrict", "userestrict", "custodhist", "altformavail", "originalsloc", "fileplan", "odd", "acqinfo", "otherfindaid", "phystech", "prefercite", "processinfo", "relatedmaterial", "scopecontent", "separatedmaterial" ]
      }
    };
});
