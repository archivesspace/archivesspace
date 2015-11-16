var app = app || {};

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


var RecordView = Backbone.View.extend({
  tagName: "div",
  initialize: function() {
    var tmpl = _.template($('#record-tmpl').html());
    this.$el.html(tmpl());
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
    var tmpl = _.template($('#container-tmpl').html());
    this.$el.html(tmpl(opts));
    return this;
  }
});




$(function() {
  var headerView = new HeaderView();
  var navbarView = new NavbarView();
});
