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


  var SearchPagerView = Bb.View.extend({
    tagName: "div",

    initialize: function(opts) {
      this.query = opts.query;
      this.resultsState = opts.resultsState;

      var pagerHelper = new this.PagerHelper(opts)

      this.$el.html(app.utils.tmpl('search-pager', pagerHelper));
    },
  });

  SearchPagerView.prototype.PagerHelper = function(opts) {

    function buildUrl(arg) {
      var result = opts.query.buildQueryString(arg);

      return result.replace(/.*\?/, opts.baseUrl+"?")
    }

    this.hasPreviousPage = opts.query.page > 1;
    this.hasNextPage = (opts.query.page < opts.resultsState.totalPages);
    this.currentPage = opts.resultsState.currentPage;


    this.getPreviousPageURL = function() {
      return buildUrl({page: opts.resultsState.currentPage - 1});
    };

    this.getPagerEnd = function() {
      return _.min([_.max([(opts.resultsState.currentPage + 5), 10]), opts.resultsState.totalPages]);
    };

    this.getPagerStart = function() {
      return _.max([opts.resultsState.currentPage - (_.max([10 - (opts.resultsState.totalPages - opts.resultsState.currentPage), 5])), 1]);
    };

    this.getNextPageURL = function() {
      return buildUrl({page: opts.resultsState.currentPage + 1});
    };

    this.getPageURL = function(page) {
      return buildUrl({page: page});
    };
  };


  function SearchResultItemPresenter(model) {
    var att = model.attributes;
    var recordJson = JSON.parse(att.json);
    this.index = model.index;
    this.title = _.get(att, 'title');
    this.recordType = att.primary_type;
    if(this.recordType === 'archival_object' && _.has(recordJson, 'title')){
      this.title = recordJson.title;
    }
    this.recordTypeClass = att.primary_type;
    this.recordTypeLabel = _.capitalize(att.primary_type);
    this.recordTypeIconClass = app.icons.getIconClass(this.recordType);
    this.identifier = att.identifier || att.uri;
    this.url = att.uri;
    this.summary = att.summary || 'Maecenas faucibus mollis <span class="searchterm2">astronomy</span>. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.';
    this.dates = [];
    this.context = undefined;
    this.relatorLabel = undefined;

    if(att.highlighting) {
      this.highlights = _.reduce(att.highlighting, function(result, list, field) {
        return _.uniq(result.concat(list));
      }, []);
    }

    this.recordTypeLabel = app.utils.getPublicTypeLabel(att.primary_type);

    this.url = app.utils.getPublicUrl(att.uri, att.primary_type);

  }


  SearchResultItemPresenter.prototype.has = function(key) {
    return !_.isUndefined(this[key])
  };


  var SearchItemView = Bb.View.extend({
    tagName: "div",

    initialize: function(opts) {
      var presenter = new SearchResultItemPresenter(this.model);
      presenter.featured = false;
      if(opts.relatorSortField) {
        var roleAndRelator = this.model.attributes[opts.relatorSortField].split(" ");
        presenter.relatorLabel = roleAndRelator[1];
        if(roleAndRelator[0] === 'creator') {
          presenter.featured = true;
        }
      }

      this.$el.html(app.utils.tmpl('search-result-row', presenter));
      this.keywordsToggle = false;
      return this;
    }
  });


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


    updateQuery: function(query, rewind) {
      if (_.isUndefined(rewind) || _.isUndefined(this.state.currentPage))
        rewind = true;

     var startPage = rewind ? 1 : this.state.currentPage;
      var state = this.state;
      state = this.state = this._checkState(_.extend({}, state, {
        query: query
      }));
      return this.getPage(startPage, _.omit({}, ["first"]));
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


    changePage: function(newPage) {
      var index = _.toInteger(newPage);
      return this.getPage(index, _.omit({}, ["first"]));
    },


    changeSort: function(newSort) {
      this.setSorting(newSort);
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


  var SearchResultsView = Bb.View.extend({
    el: ".search-results-container",

    initialize: function(opts) {
      this.query = opts.query;
      this.baseUrl = opts.baseUrl || "/search";
      return this;
    },

    events: {
      "click .pagination a": function(e) {
        e.preventDefault();
        var page = e.target.getAttribute('href').replace(/.*page=/, '')[0];
        this.trigger("changepage.aspace", page);
      },

      "click .recordrow a.record-title": function(e) {
        e.preventDefault();
        this.trigger("showrecord.aspace", e.target.getAttribute('href'));
      },

      "click .keywordscontext button": function(e) {
        e.preventDefault();
        var $container = $(e.target).closest("div");
        var $content = $(".content", $container);

        $content.toggle({duration: 400});
        // if(this.keywordsToggle) {
        //   $(".keywordscontext .content", this.$el).show();
        // } else {
        //   $(".keywordscontext .content", this.$el).hide();
        // }
      }

    },

    render: function() {
      var $el = this.$el;
      $el.empty();
      var relatorSortField;
      if(this.collection.state.sortKey && this.collection.state.sortKey.match(/_relator_sort\sasc$/)) {
        relatorSortField = this.collection.state.sortKey.replace(/\sasc/, '')
      }

      this.collection.forEach(function(item, index) {
        item.index = index;
        var searchItemView = new SearchItemView({
          model: item,
          relatorSortField: relatorSortField
        });

        $el.append(searchItemView.$el.html());
      });

      var searchPagerView = new SearchPagerView({
        query: this.query,
        resultsState: this.collection.state,
        baseUrl: this.baseUrl
      });

      $el.append(searchPagerView.$el.html());
    }
  });


  app.SearchResults = SearchResults;
  app.SearchResultsView = SearchResultsView;

})(Backbone, _);
