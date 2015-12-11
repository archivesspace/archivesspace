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

  app.utils = {

    getASType: function(type) {
      switch(type) {
      case 'collections':
      case 'collection':
        return 'resource';
      case 'objects':
      case 'object':
        return 'archival_object';
      case 'digital_object':
      case 'accession':
        return type;
      }
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
    }
  };
})();
