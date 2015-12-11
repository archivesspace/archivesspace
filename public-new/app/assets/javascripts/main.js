var app = app || {};

(function(Bb, _, $) {

  _.templateSettings.evaluate = /{([\s\S]+?)}/g;

  var HeaderView = Backbone.View.extend({
    el: "#header",
    initialize: function() {
      this.render();
    },
    render: function() {
      var tmpl = _.template($('#header-tmpl').html());
      this.$el.html(tmpl());
      return this;
    }

  });


  var NavbarView = Backbone.View.extend({
    el: "#navigation",
    initialize: function() {
      var tmpl = _.template($('#navbar-tmpl').html());
      this.$el.html(tmpl());
      return this;
    },

    events: {
      "click .top-bar-section a": function(e) {
        e.preventDefault();
        var url = e.target.getAttribute('href');
        app.router.navigate(url, {trigger: true});
      }
    }
  });


  var WelcomeView = Backbone.View.extend({
    el: "#welcome",
    initialize: function() {
      var tmpl = _.template($('#welcome-tmpl').html());
      this.$el.html(tmpl());
      return this;
    }
  });


  var ServerErrorView = Backbone.View.extend({
    tagName: "div",
    initialize: function(opts) {
      var tmpl = _.template($('#server-error-tmpl').html());
      this.$el.html(tmpl(opts.response));
      return this;
    }

  });


  var RecordView = Backbone.View.extend({
    tagName: "div",
    initialize: function(opts) {
      var tmpl = _.template($('#record-tmpl').html());
      this.$el.html(tmpl(opts.record));
      return this;
    }
  });


  var RecordSidebarView = Backbone.View.extend({
    tagName: "div",
    initialize: function() {
      var tmpl = _.template($('#record-sidebar-tmpl').html());
      this.$el.html(tmpl());
      return this;
    }
  });


  var ContainerView = Backbone.View.extend({
    el: "#container",
    initialize: function(opts) {
      opts.sidebarWidth = opts.sidebarWidth || 0;
      var tmpl = _.template($('#container-tmpl').html());
      this.$el.html(tmpl(opts));
      return this;
    }
  });


  var RecordModel = Backbone.Model.extend({
    initialize: function(opts) {
      this.type = opts.type;
      this.id = opts.id;
      this.scope = opts.repo_id ? 'repository' : 'global'
      if(this.scope === 'repository')
        this.repo_id = opts.repo_id;
      return this;
    },

    url: function() {
      var url = RAILS_API;
      if(this.scope === 'repository') {
        url += "/repositories/" + this.repo_id;
      }
      url += "/" + this.type + "s/" + this.id;

      return url;
    },

    getTitle: function() {
      return this.attributes.title;
    },

    getDisplayType: function() {
      switch (this.type) {
      case 'resource':
        return 'collection';
      case 'archival_object':
        return 'object'
      default:
        return this.type
      }
    }

  });

  app.WelcomeView = WelcomeView;
  app.RecordView = RecordView;
  app.RecordSidebarView = RecordSidebarView;
  app.ContainerView = ContainerView;
  app.RecordModel = RecordModel;
  app.ServerErrorView = ServerErrorView;

  $(function() {
    new HeaderView();
    new NavbarView();
  });
})(Backbone, _, jQuery);
