var app = app || {};


(function(Bb, _) {
  'use strict';

  function parseAdvancedQuery(query, params, depth) {
    var params = params || {};
    var depth = depth || 0;

    if (query.jsonmodel_type === "boolean_query") {
      params["op"+(depth+1)] = query.op;
      _.forEach(query.subqueries, function(subquery, i) {
        parseAdvancedQuery(subquery, params, depth+i);
      });
    } else if (query.jsonmodel_type === 'field_query') {
      params["f"+depth] = query.field;
      params["q"+depth] = query.value;
    }

    return params;
  }


  // TODO - make a JSON model for this or
  // hang it on some existing preference
  function getRecordLabelPreferences() {
    return {
      resource: {
        key_for_public_urls: "collection",
        label_singular: "Collection",
        label_plural: "Collections"
      },
      archival_object: {
        key_for_public_urls: "object",
        label_singular: "Object",
        label_plural: "Objects"
      },
      digital_object: {
        label_singular: "Digital Object"
      },
      accession: {
        key_for_public_urls: "accession",
        label_singular: "Unprocessed Material"
      },
      classification: {
        label_singular: "Record Group",
        label_plural: "Record Groups"
      },
      agent_person: {
        key_for_public_urls: "person",
        label_singular: "Person"
      },
      subject: {
        label_singular: "Subject"
      },
      repository: {
        label_singular: "Repository"
      }
    }
  }

  var recordLabelMap = getRecordLabelPreferences();

  app.utils = {

    getLabelForRecordType: function(type) {
      var result = type;

      if(_.has(recordLabelMap, type) && _.has(recordLabelMap[type], 'label_singular')) {
        result = recordLabelMap[type].label_singular;
      } else {
        _.forEach(recordLabelMap, function(mapping, asType) {
          if((mapping.key_for_public_urls === type) && mapping.label_singular) {
            result = mapping.label_singular;
          }
        });
      }

      return result;
    },


    getPublicType: function(asType) {
      if(_.has(recordLabelMap, asType) && _.has(recordLabelMap[asType], 'key_for_public_urls')) {
        return recordLabelMap[asType].key_for_public_urls;
      } else {
        return asType;
      }
    },

    getPublicTypeLabel: function(asType) {
      if(_.has(recordLabelMap, asType) && _.has(recordLabelMap[asType], 'label_singular')) {
        return recordLabelMap[asType].label_singular;
      } else {
        return asType;
      }
    },

    getASType: function(type) {
      var result = type;

      _.forEach(recordLabelMap, function(mapping, asType) {
        if (mapping.key_for_public_urls === type) {
          result = asType;
        }
      });

      return result;
    },

    getPublicUrl: function(asUri, asType) {
      return asUri.replace(new RegExp(_.pluralize(asType)), _.pluralize(app.utils.getPublicType(asType)));
    },

    convertAdvancedQuery: function(aq) {
      var params = parseAdvancedQuery(aq.query);

      return params;
    },

    flattenAdvancedQuery: function(q, result) {
      var result = result || [];
      if(q.query) {
        this.flattenAdvancedQuery(q.query, result);
      } else if(q.jsonmodel_type === "boolean_query") {
        this.flattenAdvancedQuery(q.subqueries[0], result);
        result.push(q.op);
        this.flattenAdvancedQuery(q.subqueries[1], result);
      } else if(q.jsonmodel_type === 'field_query') {
        result.push(q.field+":"+q.value);
      }
      return result;
    },

    eachAdvancedQueryRow: function(q, callback, opts) {
      var opts = opts || {
        index: 0,
      };
      if(q.query) {
        this.eachAdvancedQueryRow(q.query, callback);
      } else if(q.jsonmodel_type === "boolean_query") {
        this.eachAdvancedQueryRow(q.subqueries[0], callback, {
          index: opts.index
        });
        this.eachAdvancedQueryRow(q.subqueries[1], callback, {
          index: opts.index + 1,
          op: q.op
        });
      } else if(q.jsonmodel_type === "field_query") {
        callback({
          field: q.field,
          value: q.value,
          op: opts.op,
          index: opts.index
        }, opts.index);
      }
    },

    //TODO: cache compiled templates
    // (especially important for search result items)

    tmpl: function(templateId, data, useInnerWrapper) {
      templateId = templateId.replace(/-tmpl$/, '') + '-tmpl';
      var templateResult = _.template($('#'+templateId).html())(data);

      if(useInnerWrapper) {
        return "<div class='inner'>"+templateResult+"</div>";
      } else {
        return templateResult;
      }
    },


    formatDateString: function(date)  {
      var string = "";
      if (date.begin && date.end) {
        string += date.begin+"-"+date.end;
      } else if(date.begin) {
        string += date.begin;
      } else if(date.expression) {
        string += date.expression;
      }

      return string;
    },

    extractNoteText: function(note) {
      var subnotes = _.get(note, 'subnotes') || [];
      return _.compact([_.get(note, 'content')].concat(_.map(
        subnotes, function(subnote) {
          return _.get(subnote, 'content');
        }))).join('<br />');
    },

    formatRightsStatement: function(rightsStatement) {
      var result = [];

      _.forOwn(rightsStatement, function(val, key) {
        if(!_.includes(['lock_version', 'jsonmodel_type', 'system_mtime', 'create_time', 'last_modified_by', 'user_mtime'], key)) {
          var label = app.utils.getSchemaLabel('rights_statement', key);
          result.push("<strong>"+label+"</strong><br />"+val);
        }
      });

      return result.join("<br />");

    },

    // Not sure how to do this for real. Probably add
    // an endpoint in Rails and some caching here?
    // Depends a bit on end user workflow for customizing labels...
    getSchemaLabel: function(schema, field) {
      var field = schema + "_" + field;
      var result = field;

      switch(field) {
      case 'rights_statement_ip_status':
        result = "IP Status";
        break;
      default:
        result = _.map(result.split("_"), function(word) {
          return _.capitalize(word);
        }).join(" ");

      }

      return result;
    },

    parsePublicUrl: function(url) {
      if(url.match(/repositories\/(\d+)\/([a-z_]+)\/(\d+)$/)) {
        var parsed = /repositories\/(\d+)\/([a-z_]+)\/(\d+)/.exec(url);
        var recordTypePath = _.singularize(parsed[2]);
        return {
          repoId: parsed[1],
          recordTypePath: recordTypePath,
          asType: app.utils.getASType(recordTypePath),
          id: parsed[3]
        };
      } else {
        var parsed = /([a-z_]+)\/(\d+)/.exec(url);
        var recordTypePath = _.singularize(parsed[1])
        return {
          recordTypePath: recordTypePath,
          asType: app.utils.getASType(recordTypePath),
          id: parsed[2]
        };
      }
    },

    //drop a modal and raise it when the job
    // is done
    working: function(callback) {
      $('#wait-modal').foundation('open');
      callback(function() {
        setTimeout(function() {
          $('#wait-modal').foundation('close');
          // reinitalize foundation
          $("#main-content").foundation();
        }, 500);
      });
    }
  }
})(Backbone, _);
