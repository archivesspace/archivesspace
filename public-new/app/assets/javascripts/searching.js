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
          // apiParams['filter_term[]'] = apiParams['filter_term[]'] || [];
          // apiParams['filter_term[]'].push('{"primary_type":"'+type+'"}');
          apiParams['type'] = type
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

    return apiParams;
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

      this.render = {
        title: this.attributes.title,
        recordTypeClass: this.attributes.primary_type,
        recordTypeLabel: _.capitalize(this.attributes.primary_type),
        identifier: this.attributes.identifier || this.attributes.uri,
        url: this.attributes.uri,
        summary: this.attributes.summary || 'Maecenas faucibus mollis <span class="searchterm2">astronomy</span>. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.',
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


  // QUERY BUILDING AND REVISING
  // adding and subtracting rows, etc.
  function SearchEditor($container) {
    var $container = $container;
    var rowViews = [];
    var that = this;

    var reindexRows = function() {
      _.forEach(rowViews, function(rowView, i) {
        console.log(rowView.rowData);
        if(rowView.rowData.index != i) {
          rowView.setRowIndex(i);
        }
      });
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

      if(_.isUndefined(rowData.index)) {
        rowData.index = $(".search-query-row", $container).length;
      }

      var searchQueryRowView = new SearchQueryRowView(rowData);

      _.forEach(rowViews, function(rowView) {
        $(".add-query-row", rowView.$el).removeClass("add-query-row").addClass("remove-query-row").children("a").html("-");
        $("#search-button", rowView.$el).hide();
      });

      searchQueryRowView.on("addRow", function(e) {
        that.addRow();
      });

      searchQueryRowView.on("removeRow", function(index) {
        removeRow(index);
      });

      rowViews.push(searchQueryRowView);
      $container.append(searchQueryRowView.$el);

      //initialize select boxes
      $("button.dropdown", this.$el).each(function(i, button) {
        var placeholderText = $("ul#"+$(button).data("dropdown")+" li.selected").text();
        $(button).text(placeholderText);
      });

    };

    // take a criteria object from a result object
    // and load up the search rows
    this.loadCriteria = function(criteria) {
      var addRow = this.addRow;
      app.utils.eachAdvancedQueryRow(criteria.aq, function(rowData, i) {
        if (i === 0)
          rowData.recordType = parseRecordType(criteria);
        addRow(rowData);
      });
    }

    // export values as a criteria object
    this.extract = function() {
      var criteria = {};
      _.forEach(rowViews, function(rowView, i) {
        var $input = $("input[name='q"+i+"']", rowView.$el)
        criteria[$input.attr('name')] = $input.val();

        _.forEach($("li.selected", rowView.$el), function(elt) {
          criteria[$(elt).closest("ul").attr('id')] = $(elt).
            data('value');
        });
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
      "click .f-dropdown li a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $($a.closest("ul")).siblings("button").text($a.text());
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
      this.render();
      var tmpl = _.template($('#search-query-row-tmpl').html());
      this.$el.html(tmpl(this.rowData));
    },

    setRowIndex: function(index) {
      var oldIndex = this.rowData.index;
      this.rowData.index = index;
      _.forEach(['op', 'f'], function(ctrl) {
        $("button[data-dropdown='"+ctrl+oldIndex+"']", this.$el).attr('data-dropdown', ctrl+index).attr("aria-controls", ctrl+index);
      $("ul#"+ctrl+oldIndex, this.$el).attr("id", ctrl+index);
      });
      $("input[name='q"+oldIndex+"']", this.$el).attr('name', "q"+index);
    }
  });


  //Search Toolbar on Results Page
  var SearchToolbarView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var state = this.collection.state;
      var render = {
        pageSize: state.pageSize,
        totalRecords: state.totalRecords,
        getPageSizeURL: this.collection.getPageSizeURL,
        searchTermsString: function(spanClass) {
          if (state.criteria.q) {
            return state.criteria.q.split('+')
          } else if (state.criteria.aq) {
            return _.map(app.utils.flattenAdvancedQuery(state.criteria.aq), function(n, i) {
              if((i % 2) === 0) {
                return "<span class='"+spanClass+"'>"+n+"</span>";
              } else {
                return n;
              }
            }).join(" ");
          } else if (state.recordType) {
            return "'" + app.utils.getLabelForRecordType(state.recordType) + "' records";
          } else {
            return '*'
          }
        }
      };


      var tmpl = _.template($('#search-toolbar-tmpl').html());
      this.$el.html(tmpl(render));
      this.searchEditor = new SearchEditor($(".first-row", this.$el));
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
          this.searchEditor.loadCriteria(this.collection.state.criteria)
        }
        this.toggled = !this.toggled;
      }
    },
    search: function (e) {
      e.preventDefault();

      var url = buildBaseURL.call({
        criteria: this.searchEditor.extract()
      });
      app.router.navigate(url, {trigger: true});
    }

  });


  // Search Form on Landing Page
  var SearchBoxView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var tmpl = _.template($('#search-box-tmpl').html());
      this.$el.html(tmpl());
      this.searchEditor = new SearchEditor($("#search-form", this.$el))
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

      var url = buildBaseURL.call({
        criteria: this.searchEditor.extract()
      });

      app.router.navigate(url, {trigger: true});
    }
  });


  app.SearchQuery = SearchQuery;
  app.SearchResults = SearchResults;
  app.SearchEditor = SearchEditor;
  app.SearchBoxView = SearchBoxView;
  app.SearchToolbarView = SearchToolbarView;
  app.SearchResultsView = SearchResultsView;
  app.SearchFacetsView = SearchFacetsView;
  app.SearchQueryRowView = SearchQueryRowView;


})(Backbone, _);
