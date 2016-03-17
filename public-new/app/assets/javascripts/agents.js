var app = app || {};
(function(Bb, _, $) {


  var AgentContainerView = Bb.View.extend({
    el: "#container",

    initialize: function(opts) {
      console.log(opts);
      this.render();
    },

    render: function() {
      this.$el.html("<h1>Agent Record</h1><img src='http://motherboard-images.vice.com/content-images/contentimage/26327/1444070256569233.gif' />");
    }
  });

  app.AgentContainerView = AgentContainerView;

})(Backbone, _, jQuery);
