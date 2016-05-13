var app = app || {};

(function(Bb, _) {

  function getUrlForPage(page) {
    var current = window.location.pathname;
    var result = "";
    if(current.match(/page=\d+/)) {
      result = current.replace(/page=\d+/, "page="+page);
    } else if(current.match(/\?/)) {
      result = current + "page="+page;
    } else {
      result = current +"?page="+page;
    }
    return result;
  }

  var EmbeddedSearchView = Bb.View.extend({
    el: "#embedded-search-container",
    initialize: function(opts) {
      var data = {};
      data.title = opts.title || "Related Collections";

      this.$el.html(app.utils.tmpl('embedded-search', data));
      var $editorContainer = $("#search-editor-container", this.$el);
      this.query = new app.SearchQuery();
      this.query.advanced = true;
      this.searchEditor = new app.SearchEditor($editorContainer);
      this.searchEditor.addRow();
      this.searchResults = new app.SearchResults([], {
        state: _.merge({
          pageSize: 10
        }, opts)
      });
      app.debug.searchResults = this.searchResults;
      this.searchResults.advanced = true; //TODO - make advanced default
      this.searchResultsView = new app.SearchResultsView({
        collection: this.searchResults,
        query: this.query,
        baseUrl: opts.baseUrl
      });

      var searchResults = this.searchResults;
      var searchResultsView = this.searchResultsView;
      var destroy = $.proxy(this.destroy, this);

      this.searchResultsView.on("changepage.aspace", function(page) {
        $('#wait-modal').foundation('open');
        searchResults.changePage(page).then(function() {
          var url = getUrlForPage(page);
          app.router.navigate(url);
          searchResultsView.render();
          setTimeout(function() {
            $('#wait-modal').foundation('close');
            // reinitalize foundation
            $("#main-content").foundation();
          }, 500);
        });
      });

      this.searchResultsView.on("showrecord.aspace", function(publicUrl) {
        destroy();
        app.router.showRecord(publicUrl);
      });

      $editorContainer.addClass("search-panel-blue");

      this.update(false);

    },

    events: {
      "click #search-button" : function(e) {
        e.preventDefault();
        this.query.updateCriteria(this.searchEditor.extract());

        this.update(true);
      }

    },

    update: function(rewind) {
      var searchResultsView = this.searchResultsView;
      this.searchResults.updateQuery(this.query.toArray(), rewind).then(function() {
        searchResultsView.render();
      });
    },

    destroy: function() {
      this.unbind();
      this.$el.empty();
    }


  });


  app.EmbeddedSearchView = EmbeddedSearchView;

})(Backbone, _);
