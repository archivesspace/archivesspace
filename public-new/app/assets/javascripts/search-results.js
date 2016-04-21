var app = app || {};

var RAILS_API = "/api";

(function(Bb, _) {


  //take the raw criteria object returned by the server
  // and clean it up for our results object
  function parseCriteria(criteria) {
    if (_.has(criteria, 'aq')) {
      var aqObj = JSON.parse(criteria.aq);
      criteria.aq = aqObj;
    }

    return criteria;
  };


  var SearchResultItem = Bb.Model.extend({
    initialize: function(opts) {
      var recordJson = JSON.parse(this.attributes.json);
    },


    getURL: function() {
      var url = this.attributes.uri;
      switch(this.attributes.primary_type) {
      case 'resource':
        url = url.replace(/resources/, 'collections');
        break;
      case 'archival_object':
        url = url.replace(/archival_object/, 'object');
        break;
      }

      return url;
    },

    getDisplay: function() {
      return this.attributes.primary_type
    }
  });


  var SearchResults = Bb.PageableCollection.extend({
    model: SearchResultItem,

    url: function() {
      return RAILS_API+(this.advanced ? "/advanced_search": "/search");
    },

    parseRecords: function(data) {
      console.log(_.merge(data, {debug: "Raw search response"}));
      return data.search_data.results
    },

    parseState: function(data) {
      return {
        pageSize: data.search_data.page_size,
        lastPage: data.search_data.last_page,
        totalPages: data.search_data.last_page,
        currentPage: data.search_data.this_page,
        criteria: parseCriteria(data.search_data.criteria),
        recordType: this.parseRecordType(data.search_data.criteria),
        facetData: data.facet_data,
        filterLabelMap: data.filter_label_map,
        totalRecords: data.search_data.total_hits
      }
    },


    updateQuery: function(query) {
      var state = this.state;
      state = this.state = this._checkState(_.extend({}, state, {
        query: query
      }));

      return this.getPage(1, _.omit({}, ["first"]));
    },


    applyFilter: function(filter) {
      var filters = this.state.filters || [];
      var state = _.clone(this.state);

      if(_.has(filter, 'primary_type')) {
        state.recordType = filter['primary_type'];
      } else {
        filters.push(filter);
      }
      this.state = this._checkState(_.extend({}, state, {
        filters: filters
      }));

      return this.getPage(1, _.omit({}, ["first"]));
    },


    removeFilter: function(filterToRemove) {
      var state = _.clone(this.state);
      var filters = state.filters || [];

      if(_.has(filterToRemove, 'recordtype')) {
        state.recordType = 'any';
      } else {
        _.remove(filters, function(filter) {
          return JSON.stringify(filter) === JSON.stringify(filterToRemove);
        });
      }

      this.state = this._checkState(_.extend({}, state, {
        filters: filters
      }));

      return this.getPage(1, _.omit({}, ["first"]));
    },


    queryParams: function() {
      var map = {
        currentPage: "page",
        pageSize: "page_size",
        sortKey: 'sort',
        sort: function() {
          switch(this.state.sortKey) {
          case 'title':
            return 'title_sort asc';
          case 'date_added':
            return 'create_time asc';
          }
        },
        'filter_term[]': function() {
          if(this.state.filters) {
            return _.map(this.state.filters, function(filt) {
              return JSON.stringify(filt);
            });
          }
        }
      };

      _.times(5, function(n) {
        map['v'+n] = function() {
          if(this.state.query[n]) {
            // See - https://archivesspace.atlassian.net/browse/AR-175
            // TODO - consider putting this logic into a custom solr handler or whatever
            if(this.state.query[n]['field'] === 'identifier' && this.state.query[n]['value'].match(/\s/)) {
              return "\""+this.state.query[n]['value']+"\"";
            } else if(this.state.query[n]['field'] === 'identifier' && this.state.query[n]['value'].match(/^[a-zA-Z]+$/)) {
              return "*"+this.state.query[n]['value']+"*";
            } else {
              return this.state.query[n]['value'];
            }
          }
        };
        map['f'+n] = function() {
          if(this.state.query[n])
            return this.state.query[n]['field'];
        };
        map['op'+n] = function() {
          if(n > 0 && this.state.query[n])
            return this.state.query[n]['op'];
        };
      });

      map['type'] = function() {
        if (this.state.query[0]) {
          return this.state.query[0]['recordtype'] === 'any' ? undefined : this.state.query[0]['recordtype'];
        } else if(this.state.recordType) {
          return this.state.recordType;
        } //  else if (this.state.query[0]) {
        //   return this.state.query[0]['recordtype'] === 'any' ? undefined : this.state.query[0]['recordtype'];
        // }
      };

      return map
    }(),

  });


  SearchResults.prototype.parseRecordType = function(criteria) {
    var result = 'any';

    if(this.state.recordType) {
      result = this.state.recordType;
    } else if (_.has(criteria, 'type[]') && _.isArray(criteria['type[]']) && criteria['type[]'].length === 1) {
      result = criteria['type[]'][0];
    } else {
      var primaryTypeFilter = _.find(criteria["filter_term[]"], function(rawFilter) {
        return _.has(JSON.parse(rawFilter), 'primary_type');
      });

      if(primaryTypeFilter) {
        primaryTypeFilter = JSON.parse(primaryTypeFilter);
        result = primaryTypeFilter.primary_type;
      }
    }

    return result;
  };

  app.SearchResults = SearchResults;

})(Backbone, _);
