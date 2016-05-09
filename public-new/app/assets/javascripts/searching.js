var app = app || {};

(function(Bb, _) {

  function convertFilter(solrFilter) {
    var parsed = JSON.parse(solrFilter);
    return parsed;
  }


  // This builds a search URL to be sent to the router
  // from the internal state of a SearchResults collection +
  // an optional filter function supplied by the caller +
  // an optional param object supplied by the caller
  function buildLocationURL(paramFilter, addedParams) {
    var addedParams = addedParams || _.isUndefined(paramFilter) ? {} : _.isFunction(paramFilter) ? {} : paramFilter;

    var paramFilter = _.isFunction(paramFilter) ? paramFilter : function() {
      return true;
    };

    var url = "/search?";
    var params = [];

    if(this.pageSize) {
      params.push('pageSize='+this.pageSize);
    }

    if(this.currentPage) {
      params.push('page='+this.currentPage);
    }

    _.forEach(this.filters, function(filter) {
      params.push(_.keys(filter)[0]+"="+_.values(filter)[0]);
    });

    if(_.isArray(this.query)) {
      _.forEach(this.query, function(row, i) {
        if(row.field)
          params.push("f"+i+"="+row.field);

        if(row.value)
          params.push("q"+i+"="+row.value);

        if(row.op)
          params.push("op"+i+"="+row.op);

        if(row.recordtype && i < 1)
          params.push("recordtype="+row.recordtype);
      });
    }

    if (this.recordType) {
      params.push("recordtype="+app.utils.getPublicType(this.recordType));
    }

    params = _.filter(params, paramFilter);

    _.forOwn(addedParams, function(val, key) {
      params.push(key+"="+val);
    });

    url += params.join('&');
    return url;
  };


  //an object that can hold search
  //params taken from the public URL
  //and convert them for instantiating a SearchResults state
  function SearchQuery(queryString) {
    var that = this;
    var queryString = queryString || "";
    var publicParams = this.parseQueryString(queryString);
    publicParams.page = publicParams.page || 1;
    publicParams.pageSize = publicParams.pageSize || 20;

    _.forOwn(publicParams, function(value, key) {
      that[key] = value;
    });

    return this;
  }


  SearchQuery.prototype.forEachRow = function(cb, i) {
    var index = i || 0;
    var hasData = false;
    var that = this;
    var rowData = {
      index: index
    };
    var map = {
      'f': 'field',
      'q': 'value',
      'op': 'op'
    };

    if(index === 0 && this.recordtype)
      rowData.recordtype = this.recordtype;

    _.forEach(['f', 'q', 'op'], function(paramStem) {
      if(that[paramStem+index]) {
        rowData[map[paramStem]] = that[paramStem+index];
        hasData = true;
      }
    });

    if(hasData) {
      cb(rowData);
      this.forEachRow(cb, index+1);
    }

  };


  SearchQuery.prototype.parseQueryString = function(queryString) {
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

    if (_.isArray(params.page))
      params.page = params.page[0];

    if (_.isString(params.page))
      params.page = parseInt(params.page);

    return params;
  };


  SearchQuery.prototype.buildQueryString = function(arg1, arg2) {
    var criteria = _.pick(_.toPlainObject(this), _.isString)
    var url = buildLocationURL.call({criteria: criteria}, arg1, arg2);
    return url;
  };


  SearchQuery.prototype.updateCriteria = function(criteria) {
    var that = this;
    _.forOwn(that, function(value, key) {
      if (key.match(/^(f|q|op)\d$/)) {
        that[key] = undefined;
      }
    });

    _.forOwn(criteria, function(value, key) {
      that[key] = value;
    });
  };


  SearchQuery.prototype.toArray = function() {
    var result = [];
    this.forEachRow(function(data) {
      result.push(data);
    });

    return result;
  };


  // take the raw criteria object returned by the server
  // and figure out the 'recordtype' parameter
  // As far as our app is concerned, the 'type[]' param
  // and the filter_term[]='{'primary_type'...are redundant

  var SearchFacetsView = Bb.View.extend({
    el: "#sidebar",
    initialize: function() {
      return this;
    },

    render: function(state) {
      var helper = new this.FacetHelper(state);
      this.$el.html(app.utils.tmpl('facets', helper));
    },

    events: {
      "click .facet-group a": function(e) {
        e.preventDefault();
        var filter = $(e.target).closest("li").data("value");
        this.trigger("applyfilter.aspace", filter);
      },

      "click .applied-filters a": function(e) {
        e.preventDefault();
        var filter = $(e.target).closest("li").data("value");
        this.trigger("removefilter.aspace", filter);
      }
    }

  });


  SearchFacetsView.prototype.FacetHelper = function(state) {
    var state = state || {};

    this.addFilterURLs = {};
    this.eachUsableFacetGroup = function(cb) {
      _.forOwn(state.facetData, function(facets, facetGroup) {
        var usableFacets = _.filter(facets, function(facet) {
          return facet.count != state.totalRecords;
        });

        if (usableFacets.length > 0 ) {
          cb(usableFacets, facetGroup);
        }
      });
    };


    this.getAddFilterURL = function(filterToAdd) {
      var url = buildLocationURL.call(state, convertFilter(filterToAdd));
      return encodeURI(url);
    };


    this.getRemoveFilterURL = function(filter) {
      var url = buildLocationURL.call(state, function(param) {
        return !(param === _.keys(filter)[0]+"="+_.values(filter)[0]);
      });
      return encodeURI(url);
    };


    this.forEachAppliedFilterWithLabel = function(cb) {
      if(state.recordType && state.recordType != 'any') {
        cb({recordtype: app.utils.getPublicType(state.recordType)}, "Type: " + app.utils.getPublicTypeLabel(state.recordType));
      }

      _.forEach(state.filters, function(filter) {
        cb(filter, state.filterLabelMap[JSON.stringify(filter)]);
      });
    };
  };


  //Search Toolbar on Results Page
  var SearchToolbarView = Bb.View.extend({
    el: "#search-box",
    initialize: function(opts) {
      this.query = opts.query;

      var that = this;
      var render = {
        pageSize: this.query.pageSize
      };

      this.$el.html(app.utils.tmpl('search-toolbar', render));
      var $editorEl = opts.editorEl || $(".search-panel", this.$el);
      this.searchEditor = new app.SearchEditor($editorEl);

      return this;
    },
    events: {
      "click #search-button" : "search",
      "click #numberresults a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $("button[data-dropdown='numberresults']").text($a.text());

        var pageSize = parseInt($a.text());
        this.trigger("changepagesize.aspace", pageSize);
      },

      "click #sortorder a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $("button[data-dropdown='sortorder']").text($a.text());

        var selection = $($a.closest("li")).data("value");
        this.query.sortOrder = selection;
        this.trigger("changesortorder.aspace", selection);
      },

      "click #revise-search-button" : function(e) {
        e.preventDefault();
        this.toggled = this.toggled || false;

        if(this.toggled) {
          this.searchEditor.hide();
        } else if(this.searchEditor.loaded()) {
          this.searchEditor.show();
        } else {
          this.searchEditor.loadQuery(this.query);
        }
        this.toggled = !this.toggled;
      }
    },

    updateResultState: function(state) {
      var render = {
        searchTermsString: function(spanClass) {
          if (state.criteria.q) {
            return state.criteria.q.split('+')
          } else if (state.criteria.aq) {
            return _.map(app.utils.flattenAdvancedQuery(state.criteria.aq), function(n, i) {
              if((i % 2) === 0) {
                return "<span class='"+spanClass+"'>"+n.replace(/^.*:/, '')+"</span>";
              } else {
                return n;
              }
            }).join(" ");
          } else if (state.recordType) {
            return "'" + app.utils.getLabelForRecordType(state.recordType) + "' records";
          } else {
            return '*'
          }
        },
        totalRecords: state.totalRecords
      }

      $(".search-toolbar-results", this.$el)
        .html(app.utils.tmpl('search-toolbar-results', render));
    },


    search: function (e) {
      e.preventDefault();
      this.query.updateCriteria(this.searchEditor.extract());
      this.trigger("modifiedquery.aspace", this.query);
    }

  });


  // Search Form on Landing Page
  var SearchBoxView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      this.$el.html(app.utils.tmpl('search-box-tmpl'));
      this.searchEditor = new app.SearchEditor($(".search-editor-container", this.$el))
      this.searchEditor.addRow();
      return this;
    },
    events: {
      "click #search-button" : "search",
      "click .remove-query-row a": function(e) {
        e.preventDefault();
      }
    },
    search: function (e) {
      e.preventDefault();

      var query = new app.SearchQuery();
      query.updateCriteria(this.searchEditor.extract());

      this.trigger("newquery.aspace", query);
    }
  });


  var SearchContainerView = Bb.View.extend({
    el: "#container",
    initialize: function(query) {
      var updateLocation = false;

      if(_.isString(query)) {
        this.searchQuery = new app.SearchQuery(query);
      } else {
        this.searchQuery = query;
        updateLocation = true;
      }

      //only doing advanced search for now
      this.searchQuery.advanced = true;

      var state = {
        currentPage: this.searchQuery.page,
        pageSize: this.searchQuery.pageSize,
        query: []
      }

      var sq = this.searchQuery;

      if (sq.recordtype)
        state.recordType = app.utils.getASType(sq.recordtype);

      _.forEach(['repository', 'primary_type', 'subjects' ], function(filterKey) {
        if(sq[filterKey]){
          _.forEach(_.flatten([sq[filterKey]]), function(filterVal) {
            state.filters = state.filters || [];
            state.filters.push(JSON.parse('{"'+filterKey+'": "'+filterVal+'"}'));
          });
        }
      });

      sq.forEachRow(function(rowData, i) {
        state.query.push(rowData);
      });

      this.searchResults = new app.SearchResults([], {
        state: state
      });

      this.searchResults.advanced = true;

      app.debug = {
        results: this.searchResults,
        query: this.searchQuery
      };

      this.$el.html(app.utils.tmpl('container-tmpl', {headerText: "Search Results"}));

      this.loadToolbarAndResults();

      if(updateLocation) {
        var url = buildLocationURL.call(this.searchResults.state);
        app.router.navigate(url);
      }

      return this;
    },


    // Build the views for displaying and changing the search
    // results. Listen to views for user-driven events and trigger
    // updates to results as necessary
    // TODO 'changedates.aspace'

    loadToolbarAndResults: function() {
      var searchQuery = this.searchQuery;
      var searchResults = this.searchResults;
      var execute = $.proxy(this.execute, this);
      var redrawResults = $.proxy(this.redrawResults, this);
      var destroy = $.proxy(this.destroy, this);

      $("#main-content").addClass("search-results-container");

      var stv = this.searchToolbarView = new app.SearchToolbarView({
        query: searchQuery
      });

      var srv = this.searchResultsView = new app.SearchResultsView({
        collection: searchResults,
        query: searchQuery
      });

      var sfv = this.searchFacetsView = new app.SearchFacetsView();

      $(document).foundation();
      srv.on("showrecord.aspace", function(url) {
        var parsed = app.utils.parsePublicUrl(url);

        app.router.navigate(url);
        destroy();

        if(parsed.asType === 'repository') {
          new app.RepoContainerView(parsed);
        } else if(parsed.asType.match(/agent/)) {
          new app.AgentContainerView(parsed);
        } else {
          new app.RecordContainerView(parsed);
        }
      });


      srv.on("changepage.aspace", function(page) {
        execute('changePage', page);
      });


      sfv.on("applyfilter.aspace", function(filter) {
        execute('applyFilter', filter);
      });


      sfv.on("removefilter.aspace", function(filter) {
        execute('removeFilter', filter);
      });


      stv.on("changepagesize.aspace", function(newSize) {
        execute('setPageSize', newSize);
      });


      stv.on("changesortorder.aspace", function(newSort) {
        execute('changeSort', newSort);
      });


      stv.on("modifiedquery.aspace", function(modifiedQuery) {
        var query = [];
          // to do - add method to query object for this
        modifiedQuery.forEachRow(function(data) {
          query.push(data);
        });
        execute('updateQuery', query);
      });


      var query = [];
      searchQuery.forEachRow(function(data) {
        query.push(data);
      });

      execute('updateQuery', query);
    },


    redrawResults: function() {
      // app.debug.searchResults = this.searchResults;
      var url = buildLocationURL.call(this.searchResults.state);
      app.router.navigate(url);
      this.searchToolbarView.updateResultState(this.searchResults.state);
      this.searchResultsView.render();
      this.searchFacetsView.render(this.searchResults.state);
    },


    execute: function(method, param) {
      var searchResultMethod = $.proxy(this.searchResults[method], this.searchResults);
      var redrawResults = $.proxy(this.redrawResults, this);
      app.utils.working(function(done) {
        searchResultMethod(param).then(function() {
          redrawResults();
          done();
        });
      });
    },


    destroy: function() {
      this.unbind();
      this.$el.empty();
    }
  });


  app.SearchQuery = SearchQuery;
  app.SearchBoxView = SearchBoxView;
  app.SearchContainerView = SearchContainerView;
  app.SearchToolbarView = SearchToolbarView;
  app.SearchFacetsView = SearchFacetsView;

})(Backbone, _);
