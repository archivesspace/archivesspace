var app = app || {};

var RAILS_API = "/api";

(function(Bb, _) {

  // take a solr-style filter and convert it for our
  // public URL
  // example: '{"repositories":"/repositories/2"}'
  //    -> {repository: '/repositories/2'}
  function convertFilter(solrFilter) {
    var parsed = JSON.parse(solrFilter);
    var mapped = _.transform(parsed, function(result, val, key) {
      result[key
        .replace(/repositories/, "repository")
        .replace(/primary_type/, "recordtype")] =
        val
        .replace(/archival_object/, 'object')

    });
    return mapped;
  }


  // This builds a URL (to drive the router, not for calling the API)
  // from the internal state of a SearchResults collection +
  // an optional filter function supplied by the caller +
  // an optional param object supplied by the caller
  function buildBaseURL(paramFilter, addedParams) {
    var addedParams = addedParams || _.isUndefined(paramFilter) ? {} : _.isFunction(paramFilter) ? {} : paramFilter;

    var paramFilter = _.isFunction(paramFilter) ? paramFilter : function() {
      return true;
    };

    var url = "/search?";
    var params = [];

    if(this.pageSize) {
      params.push('pageSize='+this.pageSize);
    }
    _.forOwn(_.omit(this.criteria, ['facet[]', 'type[]']), function(value, key) {
      if(key === 'aq') {
        var aqParams = app.utils.convertAdvancedQuery(value);
        _.forOwn(aqParams, function(value, key) {
          params.push(""+key+"="+value);
        });

      } else if(_.isArray(value)) {
        _.forEach(value, function(filter) {
          params.push(""+key+"="+filter);
        });
      } else {
        params.push(key+"="+value);
      }
    });
    params = _.filter(params, paramFilter);

    _.forOwn(addedParams, function(val, key) {
      params.push(key+"="+val);
    });

    url += params.join('&');
    return url;
  };


  //an object that can hold search
  //params taken from the public URL
  //and convert them for the API
  function SearchQuery(queryString) {
    var that = this;
    var publicParams = this.parseQueryString(queryString);
    publicParams.page = publicParams.page || 1;
    publicParams.pageSize = publicParams.pageSize || 20;

    _.forOwn(publicParams, function(value, key) {
      that[key] = value;
    });

    return this;
  }


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
    return params;
  };

  // maybe all this gets pushed back to Rails
  SearchQuery.prototype.toApi = function() {
    var apiParams = {}
    _.forOwn(this, function(value, key) {
      switch(key) {
      case 'recordtype':
        var type = app.utils.getASType(value);
        if(type) {
          apiParams['filter_term[]'] = apiParams['filter_term[]'] || [];
          apiParams['filter_term[]'].push('{"primary_type":"'+type+'"}');
        }

        break;
      case 'repository':
        _.forEach(_.flatten([value]), function(repoUri) {
          apiParams['filter_term[]'] = apiParams['filter_term[]'] || [];
          apiParams['filter_term[]'].push('{"repository":"'+repoUri+'"}');
        });
        break;
      case 'subject':
        _.forEach(_.flatten([value]), function(subject) {
          apiParams['filter_term[]'] = apiParams['filter_term[]'] || [];
          apiParams['filter_term[]'].push('{"subjects":"'+subject+'"}');
        });
      default:
        apiParams[key] = value;
        break;
      }
    });

    //q0 => v0
    _.forEach(_.range(5), function(i) {
      if(apiParams['q'+i] && apiParams['f'+i]) {
        apiParams['v'+i] = apiParams['q'+i];
        delete apiParams['q'+i];
      }
    });

    console.log(apiParams);
    return apiParams;
  };


  // take the raw criteria object returned by the server
  // and figure out the 'recordtype' parameter
  function parseRecordType(criteria) {
    var primaryTypeFilter = _.find(criteria["filter_term[]"], function(rawFilter) {
      return _.has(JSON.parse(rawFilter), 'primary_type');
    });

    if(primaryTypeFilter) {
      primaryTypeFilter = JSON.parse(primaryTypeFilter);
      return primaryTypeFilter.primary_type.replace(/resource/, 'collection');
    } else {
      return 'any';
    }
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

      this.render = {
        title: this.attributes.title,
        recordTypeClass: this.attributes.primary_type,
        recordTypeLabel: _.capitalize(this.attributes.primary_type),
        identifier: this.attributes.uri,
        url: this.attributes.uri,
        summary: 'Maecenas faucibus mollis <span class="searchterm2">astronomy</span>. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.',
        dates: [],
        context: undefined
      }

      this.render.highlights = _.reduce(this.attributes.highlighting, function(result, list, field) {
        return result.concat(list);
      }, []);

      switch(this.attributes.primary_type) {
      case 'resource':
        this.render.url = this.attributes.uri.replace(/resources/, 'collections');
        this.render.recordTypeLabel = "Collection";
        break;
      case 'archival_object':
        this.render.url = this.attributes.uri.replace(/archival_object/, 'object');
        this.render.recordTypeLabel = "Object";
        break;
      case 'repository':
        this.render.title = recordJson.name;
        this.render.identifier = recordJson.repo_code;
        break;
      }
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
      if(this.advanced) {
        return RAILS_API+"/advanced_search";
      } else {
        return RAILS_API+"/search";
      }
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

    forEachAppliedFilterWithLabel: function(cb) {
      var state = this.state;
      if (!_.isEmpty(state.criteria.q)) {
        cb('q', state.filterLabelMap['q']);
      }

      _.forEach(state.criteria["filter_term[]"], function(filter) {
        cb(filter, state.filterLabelMap[filter]);
      });
    },


    eachUsableFacetGroup: function(cb) {
      var state = this.state;
      _.forOwn(state.facetData, function(facets, facetGroup) {
        var usableFacets = _.filter(facets, function(facet) {
          return facet.count != state.totalRecords;
        });

        if (usableFacets.length > 0 ) {
          cb(usableFacets, facetGroup);
        }
      });
    },


    getRemoveFilterURL: function(filterToRemove) {
      var url = buildBaseURL.call(this.state, function(param) {
        if(filterToRemove === 'q') {
          return !param.match(/^q=/);
        } else {
          return !(param === 'filter_term[]='+filterToRemove);
        }
      });
      return encodeURI(url);
    },


    getAddFilterURL: function(filterToAdd) {
      var url = buildBaseURL.call(this.state, convertFilter(filterToAdd));
      return encodeURI(url);
    },

    getPageSizeURL: function(pageSize) {
      var url = buildBaseURL.call(this.state, function(param) {
        return !param.match(/^pageSize=/);
      });
      url += "&pageSize="+pageSize;
      return encodeURI(url);
    },


    getPageURL: function(page) {
      var url = buildBaseURL.call(this.state);
      url += "&page="+page;
      return encodeURI(url);
    },

    getNextPageURL: function() {
      return this.getPageURL(this.state.currentPage + 1);
    },

    getPreviousPageURL: function() {
      return this.getPageURL(this.state.currentPage - 1);
    },

    getPagerStart: function() {
      return _.max([this.state.currentPage - (_.max([10 - (this.state.totalPages - this.state.currentPage), 5])), 1]);
    },

    getPagerEnd: function(){
      return _.min([_.max([(this.state.currentPage + 5), 10]), this.state.totalPages]);
    },

    displayTerms: function(){
      if (this.state.criteria.q) {
        return this.state.criteria.q.split('+')
      } else if (this.state.criteria.aq) {
        return app.utils.flattenAdvancedQuery(this.state.criteria.aq);
      } else {
        return '*'
      }
    },


    queryParams: {
      // firstPage: "first_page",
      currentPage: "page",
      pageSize: "page_size"
    }

  });


  var SearchFacetsView = Bb.View.extend({
    el: "#sidebar",
    initialize: function() {
      var tmpl = _.template($('#facets-tmpl').html());
      this.$el.html(tmpl(this.collection));
      return this;
    },

    events: {
      "click .facet-group a": function(e) {
        e.preventDefault();
        var url = e.target.getAttribute('href');
        app.router.navigate(url, {trigger: true});
      },

      "click .applied-filters a": function(e) {
        e.preventDefault();
        var url = e.target.getAttribute('href');
        app.router.navigate(url, {trigger: true});
      }
    }

  });


  var SearchItemView = Bb.View.extend({
    tagName: "div",
    initialize: function() {
      var tmpl = _.template($('#search-result-row-tmpl').html());
      this.$el.html(tmpl(this.model.render));
      return this;
    }
  });


  var SearchResultsView = Bb.View.extend({
    el: "#main-content",
    // tagName: "div",
    initialize: function(opts) {
      this.render();
      return this;
    },

    events: {
      "click .pagination a": function(e) {
        e.preventDefault();
        var url = e.target.getAttribute('href');
        app.router.navigate(url, {trigger: true});
      }
    },

    render: function() {
      var $el = this.$el;
      $el.html("<h2>Search results</h2>");
      this.collection.forEach(function(item, index) {
        item.render.index = index;
        var searchItemView = new SearchItemView({
          model: item
        });

        $el.append(searchItemView.$el.html());
      });

      var pagerTmpl = _.template($('#search-pager-tmpl').html());
      $el.append(pagerTmpl(this.collection));
    }
  });


  // A row in a query-builder form.
  var SearchQueryRowView = Bb.View.extend({
    tagName: 'div',
    className: 'row search-query-row',
    events: {
      "click .f-dropdown li a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $($a.closest("ul")).siblings("button").text($a.text());
      }
    },

    initialize: function(rowData) {
      this.rowData = rowData;
      this.render();
    },

    append: function($container) {
      var tmpl = _.template($('#search-box-query-row-tmpl').html());
      this.$el.html(tmpl(this.rowData));

      $(".search-query-row", $container).each(function(i, div) {
        $(".add-query-row", $(div)).removeClass("add-query-row").addClass("remove-query-row").children("a").html("-");
        $("#search-button", $(div)).hide();
      });

      $container.append(this.$el);

      //initialize select boxes
      $("button.dropdown", this.$el).each(function(i, button) {
        var placeholderText = $("ul#"+$(button).data("dropdown")+" li.selected").text();
        $(button).text(placeholderText);
      });
    }
  });


  //Search Toolbar on Results Page
  var SearchToolbarView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var tmpl = _.template($('#search-toolbar-tmpl').html());
      this.$el.html(tmpl(this.collection));
      return this;
    },
    events: {
      "click #search-button" : "search",
      "click #revise-search-button" : function(e) {
        e.preventDefault();
        this.toggled = this.toggled || false;

        if(this.toggled) {
          $(".search-query-row", this.$el).remove();
        } else {
          var that = this;
          var advancedQuery = this.collection.state.criteria.aq;

          app.utils.eachAdvancedQueryRow(advancedQuery, function(row, i) {
            if (i === 0)
              row.recordType = that.collection.state.recordType;

            var searchQueryRowView = new SearchQueryRowView(row);
            searchQueryRowView.append($(".first-row", that.$el));
          });

        }
        this.toggled = !this.toggled;
      }
    },
    search: function (e) {
      e.preventDefault();

      var state = {
        criteria: {}
      };

      _.forEach($(".search-query-row"), function($row, i) {
        var $input = $("input[name='q"+i+"']", $row)
        state.criteria[$input.attr('name')] = $input.val();

        _.forEach($("li.selected", $row), function(elt) {
          state.criteria[$(elt).closest("ul").attr('id')] = $(elt).
            data('value');
        });

      });

      var url = buildBaseURL.call(state);
      app.router.navigate(url, {trigger: true});
    }

  });


  // Search Form on Landing Page
  var SearchBoxView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var tmpl = _.template($('#search-box-tmpl').html());
      this.$el.html(tmpl());
      this.addQueryRow();
      return this;
    },
    events: {
      "click #search-button" : "search",
      "click .add-query-row a": function(e) {
        e.preventDefault();
        this.addQueryRow();
      }
    },
    search: function (e) {
      e.preventDefault();
      var state = {
        criteria: {}
      };

      _.forEach($("#search-form").serializeArray(), function(n) {
        state.criteria[n.name] = n.value;
      });

      _.forEach($("#search-form li.selected"), function(elt) {
        state.criteria[$(elt).closest("ul").attr('id')] = $(elt).
          data('value');
      });

      var url = buildBaseURL.call(state);
      app.router.navigate(url, {trigger: true});
    },

    addQueryRow: function(opts) {
      // var tmpl = _.template($('#search-box-query-row-tmpl').html());
      var opts = opts || {};

      opts.index = $(".search-query-row", this.$el).length;

      var searchQueryRowView = new SearchQueryRowView(opts);
      searchQueryRowView.append($("#search-form", this.$el));
    }
  });


  app.SearchQuery = SearchQuery;
  app.SearchResults = SearchResults;
  app.SearchBoxView = SearchBoxView;
  app.SearchToolbarView = SearchToolbarView;
  app.SearchResultsView = SearchResultsView;
  app.SearchFacetsView = SearchFacetsView;
  app.SearchQueryRowView = SearchQueryRowView;

})(Backbone, _);
