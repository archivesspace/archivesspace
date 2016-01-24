var app = app || {};

(function(Bb, _, $) {

  var RecordContainerView = Bb.View.extend({
    el: "#container",
    initialize: function(opts) {

      this.model = new app.RecordModel(opts);
      this.render();
    },

    render: function() {
      var model = this.model;
      var $el = this.$el;

      $('#search-box').remove();
      $('#welcome').remove();
      $('#wait-modal').foundation('open');

      // TODO - fetch, etc.

      model.fetch().then(function() {
        console.log(model);

        $el.html(app.utils.tmpl('record-tmpl', model));
      }).fail(function(response) {
        var errorView = new app.ServerErrorView({
          response: response
        });

        $el.html(errorView.$el.html());
      }).always(function() {
        setTimeout(function() {
          $('#wait-modal').foundation('close');
          $('#container').foundation();
        }, 500);
      });

    }
  });


  var RecordModel = Bb.Model.extend({
    initialize: function(opts) {
      this.type = opts.type;
      this.collectionType = opts.recordType;
      this.id = opts.id;
      this.scope = opts.repoId ? 'repository' : 'global'
      if(this.scope === 'repository')
        this.repoId = opts.repoId;

      return this;
    },

    url: function() {
      var url = RAILS_API;
      if(this.scope === 'repository') {
        url += "/repositories/" + this.repoId;
      }

      url += "/";

      url += this.collectionType ? this.collectionType : this.type+"s";

      url += "/"+this.id;

      return url;
    },

    getTitle: function() {
      if(this.attributes.title) {
        return this.attributes.title;
      } else if(this.attributes.jsonmodel_type == 'accession') {
        return this.attributes.id_0;
      }
    },

    getIdentifier: function() {
      return this.attributes.id_0;
    },

    getRecordType: function() {
      return this.attributes.jsonmodel_type;
    },

    getRecordTypeLabel: function() {
      return app.utils.getPublicTypeLabel(this.attributes.jsonmodel_type);
    }


    // getDisplayType: function() {
    //   switch (this.type) {
    //   case 'resource':
    //     return 'collection';
    //   case 'archival_object':
    //     return 'object'
    //   default:
    //     return this.type
    //   }
    // }

  });

  RecordModel.prototype.getAbstract = function() {
    return "Contents of the abstract field. Maecenas faucibus mollis. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.";
  }

  RecordModel.prototype.hasContentSidebar = function() {
    return this.attributes.jsonmodel_type === 'resource'
  }

  RecordModel.prototype.forEachDate = function(callback) {
    _.forEach(this.attributes.dates, function(date) {
      var dateString = app.utils.formatDateString(date);
      callback(dateString);
    });
  }

  RecordModel.prototype.hasLanguage = function() {
    if(this.attributes.jsonmodel_type === 'accession') {
      return false;
    }
  }



  app.RecordModel = RecordModel;
  app.RecordContainerView = RecordContainerView;

})(Backbone, _, jQuery);
