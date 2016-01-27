var app = app || {};

(function(Bb, _, $) {

  function RecordPresenter(model) {

    if(model.attributes.title) {
      this.title = model.attributes.title;
    } else if(model.attributes.jsonmodel_type == 'accession') {
      this.title = model.attributes.id_0;
    } else {
      this.title = "NO TITLE";
    }

    this.recordType = model.attributes.jsonmodel_type;

    this.recordTypeLabel =  app.utils.getPublicTypeLabel(this.recordType);

    if(model.attributes.identifier) {
      this.identifier = model.attributes.identifier;
    } else if(model.attributes.id_0) {
      this.identifier = model.attributes.id_0;
    } else if(model.attributes.digital_object_id) {
      this.identifier = model.attributes.digital_object_id;
    } else {
      this.identifier = "NO ID";
    }

    this.hasContentSidebar = (this.recordType === 'resource');

    this.abstract = "Contents of the abstract field. Maecenas faucibus mollis. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.";

    this.dates = _.map(model.attributes.dates, function(date) {
      return app.utils.formatDateString(date);
    });

    if(true) { // really: if scope === repo
      this.repository = {};
      this.repository.name = model.attributes.repository._resolved.name;

      var contact = _.get(model, 'attributes.repository._resolved.agent_representation._resolved.agent_contacts[0]');

      if(contact) {
        this.repository.phone = _.get(contact, 'telephones[0].number');
        this.repository.email = _.get(contact, 'email');

        this.repository.address = _.compact([
          _.get(contact, 'address_1'),
          _.get(contact, 'address_2'),
          _.get(contact, 'city')
        ]).join("<br />");
      }
    }

    if(model.attributes.subjects && model.attributes.subjects.length) {
      this.subjects = _.compact(_.map(model.attributes.subjects, function(obj) {
        return _.get(obj, '_resolved.title');
      })).sort();
    }
  }


  RecordPresenter.prototype.has = function(key) {
    return !_.isUndefined(this[key])
  };



  var RecordContainerView = Bb.View.extend({
    el: "#container",
    initialize: function(opts) {

      this.model = new app.RecordModel(opts);
      this.render();
    },

    render: function() {
      var model = this.model;
      var presenter;
      var $el = this.$el;

      $('#search-box').remove();
      $('#welcome').remove();
      $('#wait-modal').foundation('open');

      model.fetch().then(function() {
        app.debug = model;
        presenter = new RecordPresenter(model);

        $el.html(app.utils.tmpl('record', presenter));
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
      var asType = app.utils.getASType(this.collectionType.replace(/s$/, ''));
      if(this.scope === 'repository') {
        url += "/repositories/" + this.repoId;
      }

      url += "/";

      // url += this.collectionType ? this.collectionType : this.type+"s";
      url += asType+"s";

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




  app.RecordModel = RecordModel;
  app.RecordContainerView = RecordContainerView;

})(Backbone, _, jQuery);
