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


    // 1/15 - TODO: Just follow the pattern used for Search.
    // The Record is no different from the search result content
    // I.e. Just make a container view and pass it whatever
    // data the router has to send. this func should be as short
    // as the above.

    showRecord: function(repoId, collectionType, id) {
      var opts = {
        repoId: repoId,
        recordType: collectionType,
        id: id
      };

      $(function() {
        var recordContainerView = new app.RecordContainerView(opts);
      })
    },


    //   var realType = app.utils.getASType(collectionType);

    //   var record = new app.RecordModel({
    //     type: realType,
    //     collectionType: collectionType,
    //     id: id,
    //     repo_id: repoId
    //   });

    //   app.debug = record;


    //   $('#wait-modal').foundation('reveal', 'open');
    //   record.fetch().then(function(resp) {

    //     var containerView = new app.ContainerView({
    //       mainWidth: 7,
    //       sidebarWidth: 5
    //     });

    //     var recordView = new app.RecordView({
    //       record: record
    //     });
    //     var sideBar = new app.RecordSidebarView();

    //     $("#main-content").html(recordView.$el.html());
    //     $("#sidebar").html(sideBar.$el.html());

    //   }).fail(function(response) {
    //     var containerView = new app.ContainerView({
    //       mainWidth: 12,
    //     });

    //     var errorView = new app.ServerErrorView({
    //       response: response
    //     });

    //     $("#main-content").html(errorView.$el.html());
    //   }).always(function() {
    //     setTimeout(function() {
    //       $('#wait-modal').foundation('reveal', 'close');
    //     }, 500);
    //   });


    // },

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
