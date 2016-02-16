var app = app || {};

(function(Bb, $) {
  'use strict';

  var Router = Backbone.Router.extend({
    routes: {
      "": "welcome",
      "search?*queryString": "search",
      "repositories/:repo_id/:type_plural/:id": "showRecord",

      "*path": "defaultPage"
    },

    execute: function(callback, args) {
      if (callback) callback.apply(this, args);
      // $(function() {
      //   $(document).foundation('reflow');
      // });
    },


    welcome: function() {
      var welcomeView = new app.WelcomeView();
    },


    search: function(queryString) {
      $(function() {
        var searchContainerView = new app.SearchContainerView(queryString);
      });
    },


    showRecord: function(repoId, recordTypePlural, id) {
      var opts = {
        repoId: repoId,
        recordType: _.singularize(recordTypePlural),
        id: id
      };


      $(function() {
        var recordContainerView = new app.RecordContainerView(opts);
      })
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
