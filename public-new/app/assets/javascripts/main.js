// TODO -
// this file needs to lose anything
// that isn't directly related to booting the app
// in the browser.

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
        var trigger = true;

        if(url.match(/^\/search?/)) {
          var queryString = url.replace("/search?", "");
          $("#container").empty();
          // $("#welcome").empty();
          // $("#search-box").empty();
          var searchContainerView = new app.SearchContainerView(queryString);
          trigger = false;
        }

        app.router.navigate(url, {trigger: trigger});
      }
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


  // var RecordView = Backbone.View.extend({
  //   tagName: "div",
  //   initialize: function(opts) {
  //     var tmpl = _.template($('#record-tmpl').html());
  //     this.$el.html(tmpl(opts.record));
  //     return this;
  //   }
  // });


  // var RecordSidebarView = Backbone.View.extend({
  //   tagName: "div",
  //   initialize: function() {
  //     var tmpl = _.template($('#record-sidebar-tmpl').html());
  //     this.$el.html(tmpl());
  //     return this;
  //   }
  // });


  var ContainerView = Backbone.View.extend({
    el: "#container",
    initialize: function(opts) {
      opts.sidebarWidth = opts.sidebarWidth || 0;
      var tmpl = _.template($('#container-tmpl').html());
      this.$el.html(tmpl(opts));
      return this;
    }
  });

  // app.RecordView = RecordView;
  // app.RecordSidebarView = RecordSidebarView;
  app.ContainerView = ContainerView;
  app.ServerErrorView = ServerErrorView;

  $(function() {
    new HeaderView();
    new NavbarView();
    $(document).foundation();
  });
})(Backbone, _, jQuery);
