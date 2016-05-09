var app = app || {};

(function(Bb, _) {

  // QUERY BUILDING AND REVISING WIDGET
  // instantiate with a DOM container and
  // it will create and remove row views, using
  // UI events or an existing query (on page load);
  // also extracts a criteria object from widget state


  // A row in a search editor form (or container).
  var SearchQueryRowView = Bb.View.extend({
    tagName: 'div',
    className: 'row search-query-row',
    events: {
      "click ul.dropdown-pane li a": function(e) {
        e.preventDefault();
        var $a = $(e.target);
        $($a.closest("ul")).children("li").removeClass("selected");
        $($a.closest("li")).addClass("selected");
        $($a.closest("ul")).siblings("button").text($a.text());
        $($a.closest("ul")).foundation('close');
      },
      "click .add-query-row a": function(e) {
        e.preventDefault();
        this.trigger("addRow");
      },
      "click .remove-query-row a": function(e) {
        e.preventDefault();
        this.trigger("removeRow", this.rowData.index);
      }
    },

    initialize: function(rowData) {
      this.rowData = rowData;
      this.$el.html(app.utils.tmpl('search-query-row', rowData));
    },

    initDropdowns: function() {
      // initialize select boxes
      $("button.dropdown", this.$el).each(function(i, button) {
        var placeholderText = $("ul#"+$(button).data("toggle")+" li.selected").text();
        $(button).text(placeholderText);
      });

      this.$el.foundation();
    },

    setRowIndex: function(index) {
      this.rowData.index = index;
    },

    close: function() {
      this.remove();
      this.unbind();
    }
  });


  function SearchEditor($container) {
    var $container = $container;
    var rowViews = [];
    var that = this;
    var counter = 0;
    var loaded = false;

    var reindexRows = function() {
      _.forEach(rowViews, function(rowView, i) {
        rowView.rowData.index = i;
      });

      // make sure the first row doesn't have
      // a boolean dropdown
      $("div.boolean-dropdown", rowViews[0].$el).html("&#160;");
    };

    var removeRow = function(rowIndex) {
      var rowToRemove = rowViews[rowIndex];
      rowViews = _.reject(rowViews, function(n, i) {
        return i === rowIndex;
      });

      if(rowIndex === 0) {
        var $recordTypeCol = $(".search-query-recordtype-col", rowToRemove.$el).detach();
        $(".search-query-recordtype-col", rowViews[0].$el).replaceWith($recordTypeCol);
      }

      rowToRemove.remove();
      reindexRows();
    };

    this.addRow = function(rowData) {
      var rowData = rowData || {};
      rowData.rowId = counter;
      counter += 1;

      if(_.isUndefined(rowData.index)) {
        rowData.index = $(".search-query-row", $container).length;
      }

      var newRowView = new SearchQueryRowView(rowData);

      _.forEach(rowViews, function(rowView) {
        $(".add-query-row", rowView.$el).removeClass("add-query-row").addClass("remove-query-row").children("a").html("-");
        $("#search-button", rowView.$el).hide();
      });

      newRowView.on("addRow", function(e) {
        that.addRow();
      });

      newRowView.on("removeRow", function(index) {
        removeRow(index);
      });

      rowViews.push(newRowView);
      $container.append(newRowView.$el);
      newRowView.initDropdowns();
    };

    this.loadQuery = function(query) {
      var addRow = this.addRow;
      query.forEachRow(function(rowData) {
        addRow(rowData);
      });

      addRow();
      loaded = true;
    }

    this.loaded = function() {
      return loaded;
    },

    this.hide = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.$el.hide();
      });
    },

    this.show = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.$el.show();
      });
    },


    this.close = function() {
      _.forEach(rowViews, function(rowView) {
        rowView.close();
      });
    },

    // export values as a criteria object
    this.extract = function() {
      var criteria = {};
      var i = 0;
      _.forEach(rowViews, function(rowView) {
        var rowId = rowView.rowData.rowId;
        var queryVal = $("input", rowView.$el).val();

        if(queryVal && queryVal.length) {
          criteria["q"+i] = queryVal;
          _.forEach($("li.selected", rowView.$el), function(elt) {
            var name = $(elt).closest("ul").data('name');
            name = (name === 'recordtype' ? name : name + i);
            criteria[name] = $(elt).data('value');
          });
          i += 1;
        }
      });

      return criteria;
    };

    return this;
  };

  app.SearchEditor = SearchEditor;

})(Backbone, _);
