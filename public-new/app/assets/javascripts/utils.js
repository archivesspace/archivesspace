var app = app || {};


(function() {
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
        key_for_public_urls: "object"
      },
      accession: {
        key_for_public_urls: "accession",
        label_singular: "Unprocessed Material"
      },
      classification: {
        label_singular: "Record Group",
        label_plural: "Record Groups"
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
          if(mapping.key_for_public_urls === type && mapping.label_sungular);
          result = mapping.label_singular;
        });
      }

      return result;
    },


    getPublicType: function(asType) {
      if(_.has(recordLabelMap, asType)) {
        return recordLabelMap[asType].key_for_public_urls;
      } else {
        return asType;
      }
    },

    getPublicTypeLabel: function(asType) {
      if(_.has(recordLabelMap, asType)) {
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

    tmpl: function(templateId, data) {
      templateId = templateId.replace(/-tmpl$/, '') + '-tmpl';
      return _.template($('#'+templateId).html())(data);
    },


    formatDateString: function(date)  {
      var string = "";
      if (date.begin && date.end) {
        string += date.begin+"-"+date.end;
      } else if(date.begin) {
        string += date.begin
      }

      return string;
    }




  }
})();
