var app = app || {};


(function() {
  'use strict';

  function parseQueryString(queryString){
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
  }

  
  var Router = Backbone.Router.extend({
    routes: {
      "": "welcome",
      "search?*queryString": "showSearchResults",
      "repositories/:repo_id/collections/:id": "showResource"
    },

    welcome: function() {
      var welcomeView = new WelcomeView();
      var searchBoxView = new SearchBoxView();
    },


    showSearchResults: function(queryString) {
      var searchParams = parseQueryString(queryString);

      searchParams.page = searchParams.page || 1;
      console.log(searchParams);

      var searchResults = new SearchResults([], {
        state: {
          currentPage: searchParams.page
        }
      });

      app.debug = searchResults;
      $('#wait-modal').foundation('reveal', 'open');
      searchResults.fetch({data: searchParams}).then(function() {
        var containerView = new ContainerView({
          mainWidth: 9,
          sidebarWidth: 3
        });

        var searchResultsView = new SearchResultsView({
          collection: searchResults,
          searchParams: searchParams
        });

        var sideBar = new SearchFacetsView({
          collection: searchResults
        });

        $.scrollTo($('#header'));
        $('#wait-modal').foundation('reveal', 'close');  
      });
    },



    showResource: function() {      
      var containerView = new ContainerView({
        mainWidth: 7,
        sidebarWidth: 5
      });
      
      var recordView = new RecordView();
      var sideBar = new RecordSidebarView();

      $("#main-content").html(recordView.$el.html());
      $("#sidebar").html(sideBar.$el.html());
    }
  });


  $(function() {
    app.router = new Router();
    Backbone.history.start();
  });
})();


