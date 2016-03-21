var app = app || {};
(function(Bb, _, $) {

  var WelcomeView = Backbone.View.extend({
    el: "#container",
    initialize: function() {
      var that = this;
      var tmpl = _.template($('#welcome-tmpl').html());
      this.$el.html(tmpl());

      var searchBoxView = new app.SearchBoxView();
      searchBoxView.on("submitquery.aspace", function(newQuery){
        console.log(newQuery);
        var query = [];
        newQuery.forEachRow(function(data) {
          query.push(data);
        });

        var queryString = newQuery.buildQueryString();
        var searchContainerView = new app.SearchContainerView(queryString);

        searchBoxView.unbind();
        searchBoxView.remove();

        this.unbind();
        this.remove();

      });


      return this;
    }
  });

  app.WelcomeView = WelcomeView;

})(Backbone, _, jQuery);
