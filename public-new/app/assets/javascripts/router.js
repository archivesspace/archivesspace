var app = app || {};

(function(Bb, $) {
  'use strict';

  var Router = Backbone.Router.extend({
    routes: {
      "": "welcome",
      "search?*queryString": "showSearchResults",
      "repositories/:repo_id/:type_plural/:id": "showRecord",

      "*path": "defaultPage"
    },

    execute: function(callback, args) {
      if (callback) callback.apply(this, args);
      $(document).foundation();
    },


    welcome: function() {
      var welcomeView = new app.WelcomeView();
      var searchBoxView = new app.SearchBoxView();
    },


    showSearchResults: function(queryString) {
      // var query = app.utils.parseQueryString(queryString);
      var searchQuery = new app.SearchQuery(queryString);

      //only doing advanced search for now
      searchQuery.advanced = true;

      var searchResults = new app.SearchResults([], {
        state: {
          currentPage: searchQuery.page,
          pageSize: searchQuery.pageSize
        }
      });

      searchResults.advanced = true;

      app.debug = searchResults;

      $('#wait-modal').foundation('reveal', 'open');
      var opts = {data: searchQuery.toApi()};
      console.log(_.merge(opts, {what: "search query parsed from URL and prepared for fetching from the API"}));
      searchResults.fetch(opts).then(function() {
        $("#search-box").empty();
        var searchToolbarView = new app.SearchToolbarView({
          collection: searchResults,
          searchParams: searchQuery
        });

        var containerView = new app.ContainerView({
          mainWidth: 9,
          sidebarWidth: 3
        });

        var searchResultsView = new app.SearchResultsView({
          collection: searchResults,
          searchParams: searchQuery
        });

        var sideBar = new app.SearchFacetsView({
          collection: searchResults
        });

        $.scrollTo($('#header'));
        $('#wait-modal').foundation('reveal', 'close');
        //Sometimes the modal doesn't have time to finish opening
        //and misses the first close call
        setTimeout(function() {
          $('#wait-modal').foundation('reveal', 'close');
          // reinitalize foundation
          $(document).foundation();
        }, 500);

      });
    },


    showRecord: function(repo_id, type_plural, id) {
      var realType = app.utils.getASType(type_plural);


      var record = new app.RecordModel({
        type: realType,
        id: id,
        repo_id: repo_id
      });

      app.debug = record;


      $('#wait-modal').foundation('reveal', 'open');
      record.fetch().then(function() {
        var containerView = new app.ContainerView({
          mainWidth: 7,
          sidebarWidth: 5
        });
      
        var recordView = new app.RecordView({
          record: record
        });
        var sideBar = new app.RecordSidebarView();

        $("#main-content").html(recordView.$el.html());
        $("#sidebar").html(sideBar.$el.html());

      }).fail(function(response) {
        var containerView = new app.ContainerView({
          mainWidth: 12,
        });

        var errorView = new app.ServerErrorView({
          response: response
        });

        $("#main-content").html(errorView.$el.html());
      }).always(function() {
        setTimeout(function() {
          $('#wait-modal').foundation('reveal', 'close');
        }, 500);
      });


    },

    defaultPage: function(path) {
      var containerView = new app.ContainerView({
        mainWidth: 12,
        sidebarWidth: 0
      });

      $("#main-content").html("<h1>Route not found</h1><p>"+path+"</p>");
    }
  });


  $(function() {
    app.router = new Router();
    Bb.history.start({pushState: true});
  });
})(Backbone, jQuery);


