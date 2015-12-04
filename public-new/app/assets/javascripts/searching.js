var app = app || {};

var RAILS_API = "/api";

(function(Bb, _) {

  // This builds a URL for the location toolbar (not Ajax calls)
  // from the internal state of a SearchResults collection
  function buildBaseURL(filter) {
    var filter = filter || function() {
      return true;
    };

    var url = "/search?";
    var params = [];

    if(this.state.pageSize) {
      params.push('pageSize='+this.state.pageSize);
    }
    _.forOwn(_.pick(this.state.criteria, ['q', 'filter_term[]']), function(value, key) {
      if(_.isArray(value)) {
        _.forEach(value, function(filter) {
          params.push(""+key+"="+filter);
        });
      } else {
        params.push(key+"="+value);
      }
    });
    params = _.filter(params, filter);

    url += params.join('&');
    return url;
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

    url: RAILS_API+"/search",

    parseRecords: function(data) {
      console.log(data);
      return data.search_data.results
    },

    parseState: function(data) {
      return {
        pageSize: data.search_data.page_size,
        lastPage: data.search_data.last_page,
        totalPages: data.search_data.last_page,
        currentPage: data.search_data.this_page,
        criteria: data.search_data.criteria,
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
      var url = buildBaseURL.call(this, function(param) {
        if(filterToRemove === 'q') {
          return !param.match(/^q=/);
        } else {
          return !(param === 'filter_term[]='+filterToRemove);
        }
      });
      return encodeURI(url);
    },


    getAddFilterURL: function(filterToAdd) {
      var url = buildBaseURL.call(this);
      url += "&filter_term[]="+filterToAdd;
      return encodeURI(url);
    },

    getPageSizeURL: function(pageSize) {
      var url = buildBaseURL.call(this, function(param) {
        return !param.match(/^pageSize=/);
      });
      url += "&pageSize="+pageSize;
      return encodeURI(url);
    },


    getPageURL: function(page) {
      var url = buildBaseURL.call(this);
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
        return this.state.criteria.q
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
      console.log(this.model);
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
      $el.foundation();
    }
  });


  //Search Toolbar on Results Page
  var SearchToolbarView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var tmpl = _.template($('#search-toolbar-tmpl').html());
      this.$el.html(tmpl(this.collection));
      $(document).foundation();
      return this;
    },
    events: {
      "click #search-button" : "search"
    },
    search: function (e) {
      e.preventDefault();

      app.router.navigate('/search?' + $('#search-form').serialize(), {trigger: true});
    }

  });


  // Search Form on Landing Page
  var SearchBoxView = Bb.View.extend({
    el: "#search-box",
    initialize: function() {
      var tmpl = _.template($('#search-box-tmpl').html());
      this.$el.html(tmpl());
      return this;
    },
    events: {
      "click #search-button" : "search"
    },
    search: function (e) {
      e.preventDefault();

      app.router.navigate('/search?' + $('#search-form').serialize(), {trigger: true});
    }
  });


  app.SearchResults = SearchResults;
  app.SearchBoxView = SearchBoxView;
  app.SearchToolbarView = SearchToolbarView;
  app.SearchResultsView = SearchResultsView;
  app.SearchFacetsView = SearchFacetsView;

})(Backbone, _);
