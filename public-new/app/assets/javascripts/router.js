var app = app || {};

(function(Bb, $) {
  'use strict';

  var Router = Backbone.Router.extend({
    routes: {
      "": "welcome",
      "search?*queryString": "search",
      "repositories/:repo_id/:type_plural/:id": "showArchivalRecord",
      "agents/:type_plural/:id": "showAgentRecord",
      "subjects/:id": "showSubjectRecord",
      "repositories/:id(?*params)": "showRepoRecord",
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


    showArchivalRecord: function(repoId, recordTypePathPlural, id) {
      var opts = {
        repoId: repoId,
        recordTypePath: _.singularize(recordTypePathPlural),
        id: id
      };


      $(function() {
        var recordContainerView = new app.RecordContainerView(opts);
      })
    },


    // load the right container view and navigate
    // to record url
    showRecord: function(publicUrl) {
      this.navigate(publicUrl);
      var parsed = app.utils.parsePublicUrl(publicUrl);

      if(parsed.asType === 'repository') {
          new app.RepoContainerView(parsed);
      } else if(parsed.asType.match(/agent/)) {
        new app.AgentContainerView(parsed);
      } else if(parsed.asType === 'subject') {
        new app.SubjectContainerView(parsed);
      } else {
        new app.RecordContainerView(parsed);
      }
    },


    showRepoRecord: function(id, params) {
      var opts = {
        id: id
      };

      if(params)
        _.merge(opts, app.SearchQuery.prototype.parseQueryString(params));


      $(function() {
        var repoContainerView = new app.RepoContainerView(opts);
      })
    },


    showAgentRecord: function(publicTypePlural, id) {
      var opts = {
        type: _.singularize(publicTypePlural),
        id: id
      };


      $(function() {
        var agentContainerView = new app.AgentContainerView(opts);
      })
    },


    showSubjectRecord: function(id) {
      var opts = {
        id: id
      };

      $(function() {
        var subjectContainerView = new app.SubjectContainerView(opts);
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
