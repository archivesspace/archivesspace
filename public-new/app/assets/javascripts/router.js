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
      var searchBoxView = new app.SearchBoxView();
    },


    search: function(queryString) {
      var searchContainerView = new app.SearchContainerView(queryString);
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
