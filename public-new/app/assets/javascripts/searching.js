var app = app || {};

var RAILS_API = "/api";

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
      params.push("recordtype="+this.recordType);
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

  function parseRecordType(criteria) {
    var result = 'any';

    if (_.has(criteria, 'type[]') && _.isArray(criteria['type[]']) && criteria['type[]'].length === 1) {
      result = app.utils.getPublicType(criteria['type[]'][0]);
    } else {
      var primaryTypeFilter = _.find(criteria["filter_term[]"], function(rawFilter) {
        return _.has(JSON.parse(rawFilter), 'primary_type');
      });

      if(primaryTypeFilter) {
        primaryTypeFilter = JSON.parse(primaryTypeFilter);
        result = app.utils.getPublicType(primaryTypeFilter.primary_type);
      }
    }

    return result;
  };


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
        recordType: parseRecordType(data.search_data.criteria),
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
      console.log(state);

      return this.getPage(1, _.omit({}, ["first"]));
    },


    applyFilter: function(filter) {
      var filters = this.state.filters || [];
      var state = this.state;
      filters.push(filter);
      state = this.state = this._checkState(_.extend({}, state, {
        filters: filters
      }));

      return this.getPage(1, _.omit({}, ["first"]));
    },


    removeFilter: function(filterToRemove) {
      var filters = this.state.filters || [];
      _.remove(filters, function(filter) {
        return JSON.stringify(filter) === JSON.stringify(filterToRemove);
      });

      var state = this.state;
      state = this.state = this._checkState(_.extend({}, state, {
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
          if(this.state.query[n])
            return this.state.query[n]['value'];
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
      _.forEach(state.filters, function(filter) {
        cb(filter, state.filterLabelMap[JSON.stringify(filter)]);
      });
    };
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

    this.hasPreviousPage = opts.query.page > 1;
    this.hasNextPage = (opts.query.page < opts.resultsState.totalPages);
    this.currentPage = opts.resultsState.currentPage;


    this.getPreviousPageURL = function() {
      return opts.query.buildQueryString({page: opts.resultsState.currentPage - 1});
    };

    this.getPagerEnd = function() {
      return _.min([_.max([(opts.resultsState.currentPage + 5), 10]), opts.resultsState.totalPages]);
    };

    this.getPagerStart = function() {
      return _.max([opts.resultsState.currentPage - (_.max([10 - (opts.resultsState.totalPages - opts.resultsState.currentPage), 5])), 1]);
    };

    this.getNextPageURL = function() {
      return opts.query.buildQueryString({page: opts.resultsState.currentPage + 1});
    };

    this.getPageURL = function(page) {
      return opts.query.buildQueryString({page: page});
    };
  };

  function SearchResultItemPresenter(model) {
    var att = model.attributes;
    var recordJson = JSON.parse(att.json);
    this.index = model.index;
    this.title = _.get(att, 'title');
    this.recordType = att.primary_type;
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

    switch(att.primary_type) {
    case 'resource':
      this.url = att.uri.replace(/resources/, 'collections');
      this.recordTypeLabel = "Collection";
      break;
    case 'archival_object':
      this.url = att.uri.replace(/archival_object/, 'object');
      this.recordTypeLabel = "Object";
      break;
    case 'repository':
      this.title = recordJson.name;
      this.identifier = recordJson.repo_code;
      break;
    }
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


  var SearchResultsView = Bb.View.extend({
    el: ".search-results-container",

    initialize: function(opts) {
      this.query = opts.query;
      return this;
    },

    events: {
      "click .pagination a": function(e) {
        e.preventDefault();
        var url = e.target.getAttribute('href');
        app.router.navigate(url, {trigger: true});
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
      console.log(relatorSortField);

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
        resultsState: this.collection.state
      });

      $el.append(searchPagerView.$el.html());
    }
  });


  // QUERY BUILDING AND REVISING WIDGET
  // instantiate with a DOM container and
  // it will create and remove row views, using
  // UI events or an existing query (on page load);
  // also extracts a criteria object from widget state
  function SearchEditor($container) {
    var $container = $container;
    var rowViews = [];
    var that = this;
    var counter = 0;
    var loaded = false;

    var reindexRows = function() {
      _.forEach(rowViews, function(rowView, i) {
        rowView.rowData.index = i;
      });

      // make sure the first row doesn't have
      // a boolean dropdown
      $("div.boolean-dropdown", rowViews[0].$el).html("&#160;");
    };

    var removeRow = function(rowIndex) {
      var rowToRemove = rowViews[rowIndex];
      rowViews = _.reject(rowViews, function(n, i) {
        return i === rowIndex;
      });

      if(rowIndex === 0) {
        var $recordTypeCol = $(".search-query-recordtype-col", rowToRemove.$el).detach();
        $(".search-query-recordtype-col", rowViews[0].$el).replaceWith($recordTypeCol);
      }

      rowToRemove.remove();
      reindexRows();
    };

    this.addRow = function(rowData) {
      var rowData = rowData || {};
      rowData.rowId = counter;
      counter += 1;

      if(_.isUndefined(rowData.index)) {
        rowData.index = $(".search-query-row", $container).length;
      }

      var newRowView = new SearchQueryRowView(rowData);

      _.forEach(rowViews, function(rowView) {
        $(".add-query-row", rowView.$el).removeClass("add-query-row").addClass("remove-query-row").children("a").html("-");
        $("#search-button", rowView.$el).hide();
      });

      newRowView.on("addRow", function(e) {
        that.addRow();
      });

      newRowView.on("removeRow", function(index) {
        removeRow(index);
      });

      rowViews.push(newRowView);
      $container.append(newRowView.$el);
      newRowView.initDropdowns();
    };

    this.loadQuery = function(query) {
      var addRow = this.addRow;
      query.forEachRow(function(rowData) {
        addRow(rowData);
      });

      addRow();
      loaded = true;
    }

    this.loaded = function() {
      return loaded;
    },

    this.hide = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.$el.hide();
      });
    },

    this.show = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.$el.show();
      });
    },


    this.close = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.close();
      });
    },

    // export values as a criteria object
    this.extract = function() {
      var criteria = {};
      var i = 0;
      _.forEach(rowViews, function(rowView) {
        var rowId = rowView.rowData.rowId;
        var queryVal = $("input", rowView.$el).val();

        if(queryVal && queryVal.length) {
          criteria["q"+i] = queryVal;
          _.forEach($("li.selected", rowView.$el), function(elt) {
            var name = $(elt).closest("ul").data('name');
            name = (name === 'recordtype' ? name : name + i);
            criteria[name] = $(elt).data('value');
          });
          i += 1;
        }
      });

      return criteria;
    };

    return this;
  };


  // A row in a search editor form (or container).
  var SearchQueryRowView = Bb.View.extend({
    tagName: 'div',
    className: 'row search-query-row',
    events: {
      "click ul.dropdown-pane li a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $($a.closest("ul")).siblings("button").text($a.text());
        $($a.closest("ul")).foundation('close');
      },
      "click .add-query-row a": function(e) {
        e.preventDefault();
        this.trigger("addRow");
      },
      "click .remove-query-row a": function(e) {
        e.preventDefault();
        this.trigger("removeRow", this.rowData.index);
      }
    },

    initialize: function(rowData) {
      this.rowData = rowData;
      this.$el.html(app.utils.tmpl('search-query-row', rowData));
    },

    initDropdowns: function() {
      // initialize select boxes
      $("button.dropdown", this.$el).each(function(i, button) {
        var placeholderText = $("ul#"+$(button).data("toggle")+" li.selected").text();
        $(button).text(placeholderText);
      });

      this.$el.foundation();
    },

    setRowIndex: function(index) {
      this.rowData.index = index;
    },

    close: function() {
      this.remove();
      this.unbind();
    }
  });


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
      this.searchEditor = new SearchEditor($editorEl);

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
      this.searchEditor = new SearchEditor($(".search-editor-container", this.$el))
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

      // app.debug = {
      //   results: this.searchResults,
      //   query: this.searchQuery
      // };

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
        var parsed = /repositories\/(\d+)\/([a-z_]+)\/(\d+)/.exec(url)
        var opts = {
          repoId: parsed[1],
          recordType: _.singularize(parsed[2]),
          id: parsed[3]
        }
        app.router.navigate(url);
        destroy();
        new app.RecordContainerView(opts);
      });


      sfv.on("applyfilter.aspace", function(filter) {
        $('#wait-modal').foundation('open');
        searchResults.applyFilter(filter).then(function() {
          var url = buildLocationURL.call(searchResults.state);
          app.router.navigate(url);
          redrawResults();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            // reinitalize foundation
            $("#main-content").foundation();
          }, 500);
        });
      });


      sfv.on("removefilter.aspace", function(filter) {
        $('#wait-modal').foundation('open');
        searchResults.removeFilter(filter).then(function() {
          var url = buildLocationURL.call(searchResults.state);
          app.router.navigate(url);
          redrawResults();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            // reinitalize foundation
            $("#main-content").foundation();
          }, 500);
        });
      });

      stv.on("changepagesize.aspace", function(newSize) {
        $('#wait-modal').foundation('open');
        searchResults.setPageSize(newSize).then(function() {
          redrawResults();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            $("#main-content").foundation();
          }, 500);
        });
      });

      stv.on("changesortorder.aspace", function(newSort) {
        $('#wait-modal').foundation('open');
        searchResults.setSorting(newSort);
        searchResults.fetch().then(function() {
          redrawResults();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            $("#main-content").foundation();
          }, 500);
        });
      });

      stv.on("modifiedquery.aspace", function(modifiedQuery) {
        console.log("modifiedquery.aspace");
        var query = [];
          // to do - add method to query object for this
        modifiedQuery.forEachRow(function(data) {
          query.push(data);
        });
        $('#wait-modal').foundation('open');
        searchResults.updateQuery(query).then(function() {
          var url = buildLocationURL.call(searchResults.state);
          app.router.navigate(url);
          redrawResults();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            // reinitalize foundation
            $("#main-content").foundation();
          }, 500);
        });
      });


      // $(function() {
      //   stv.trigger("modifiedquery.aspace", searchQuery);
      // });

      var query = [];
      searchQuery.forEachRow(function(data) {
        query.push(data);
      });
      $('#wait-modal').foundation('open');
      searchResults.updateQuery(query).then(function() {
        redrawResults();
        setTimeout(function() {
          $('#wait-modal').foundation('close');
          $("#main-content").foundation();
        }, 500);
      });

    },

    redrawResults: function() {
      this.searchToolbarView.updateResultState(this.searchResults.state);
      this.searchResultsView.render();
      this.searchFacetsView.render(this.searchResults.state);
    },

    destroy: function() {
      this.unbind();
      this.$el.empty();
    }
  });


  var EmbeddedSearchView = Bb.View.extend({
    el: "#embedded-search-container",
    initialize: function(opts) {
      this.$el.html(app.utils.tmpl('embedded-search'));
      var $editorContainer = $("#search-editor-container", this.$el);
      this.query = new SearchQuery();
      this.query.advanced = true;
      this.searchEditor = new SearchEditor($editorContainer);
      this.searchEditor.addRow();
      this.searchResults = new app.SearchResults([], {
        state: _.merge({
          pageSize: 10
        }, opts)
      });
      this.searchResults.advanced = true; //TODO - make advanced default
      this.searchResultsView = new app.SearchResultsView({
        collection: this.searchResults,
        query: this.query
      });

      $editorContainer.addClass("search-panel-blue");

      this.update();

    },

    events: {
      "click #search-button" : function(e) {
        e.preventDefault();
        this.query.updateCriteria(this.searchEditor.extract());

        this.update();
      }

    },

    update: function() {
      var searchResultsView = this.searchResultsView;
      this.searchResults.updateQuery(this.query.toArray()).then(function() {
        searchResultsView.render();
      });
    }


  })


  app.SearchQuery = SearchQuery;
  app.SearchResults = SearchResults;
  app.SearchEditor = SearchEditor;
  app.SearchBoxView = SearchBoxView;
  app.SearchContainerView = SearchContainerView;
  app.SearchToolbarView = SearchToolbarView;
  app.SearchResultsView = SearchResultsView;
  app.SearchFacetsView = SearchFacetsView;
  app.SearchQueryRowView = SearchQueryRowView;
  app.SearchPagerView = SearchPagerView;
  app.EmbeddedSearchView = EmbeddedSearchView;

})(Backbone, _);
