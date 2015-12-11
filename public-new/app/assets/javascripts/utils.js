var app = app || {};


(function() {
  'use strict';

  app.utils = {
    parseQueryString: function(queryString){
      var params = {};
      if(queryString){
        _.each(
          _.map(decodeURI(queryString).split(/&/g),function(el,i){
            var aux = el.split('='), o = {};
            if(aux.length >= 1){
              var val = undefined;
              if(aux.length == 2)
                val = aux[1];
              o[aux[0]] = val;            
            }
          return o;
          }),
          function(o){
            _.assign(params,o, function(value, other) {
              if (_.isUndefined(value)) {
                return other;
              } else {
                return _.flatten([value, other]);
              }
            });
          }
        );
      }
    return params;
    },

    getASType: function(type) {
      switch(type) {
      case 'collections':
        return 'resource';
      case 'collection':
        return 'resource';
      case 'objects':
        return 'archival_object';
      }
    }
  };
})();
