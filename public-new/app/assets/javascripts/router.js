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

    welcome: function() {
      var welcomeView = new app.WelcomeView();
      var searchBoxView = new app.SearchBoxView();
    },


    showSearchResults: function(queryString) {
      var searchParams = app.utils.parseQueryString(queryString);

      searchParams.page = searchParams.page || 1;
      console.log(searchParams);

      var searchResults = new app.SearchResults([], {
        state: {
          currentPage: searchParams.page,
          pageSize: searchParams.pageSize || 20
        }
      });

      app.debug = searchResults;

      $('#wait-modal').foundation('reveal', 'open');
      searchResults.fetch({data: searchParams}).then(function() {
        $("#search-box").empty();
        var searchToolbarView = new app.SearchToolbarView({
          collection: searchResults,
          searchParams: searchParams
        });

        var containerView = new app.ContainerView({
          mainWidth: 9,
          sidebarWidth: 3
        });

        var searchResultsView = new app.SearchResultsView({
          collection: searchResults,
          searchParams: searchParams
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


