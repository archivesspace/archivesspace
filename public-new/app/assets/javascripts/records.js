var app = app || {};
(function(Bb, _, $) {

  function RecordPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);

    this.representativeImage = _.get(model, 'attributes.representative_image.file_uri')

    this.representativeImageCaption = _.get(model, 'attributes.representative_image.caption') || "<i>No caption</i>";

    if(model.attributes.title) {
      this.title = model.attributes.title;
    } else if(model.attributes.jsonmodel_type == 'accession') {
      this.title = model.attributes.id_0;
    } else {
      this.title = "NO TITLE";
    }

    if(_.get(model, 'attributes.notes')) {
      var scopenote = _.find(model.attributes.notes, function(note) {
        return _.get(note, 'type') === 'scopecontent';
      });

      if(scopenote) {
        this.abstract = app.utils.extractNoteText(scopenote);
      } else {
        var abstractnote = _.find(model.attributes.notes, function(note) {
          return _.get(note, 'type') === 'abstract';
        });

        if(abstractnote)
          this.abstract = app.utils.extractNoteText(abstractnote);
      }
    }


    switch(this.recordType) {
    case 'resource':
      this.hasContentSidebar = true;
      // this.hasAccordion = true;
      this.hasOuterBorder = true;
      this.hasToolbar = true;
      this.hasFullWidthContext = true;
      break;
    case 'classification':
      // this.hasAccordion = false;
      this.hasOuterBorder = false;
      this.hasContentSidebar = true;
      this.hasToolbar = false;
      this.hasFullWidthContext = false;
      this.abstract = _.get(model, 'attributes.description');
      var creator = _.get(model, 'attributes.creator._resolved');
      if(creator)
        this.creator = "<a href='"+creator.uri+"'>"+creator.title+"</a>";

      break;

    case 'classification_term':
      // this.hasAccordion = false;
      this.hasOuterBorder = false;
      this.hasContentSidebar = true;
      this.hasToolbar = false;
      this.hasFullWidthContext = false;
      break;

    default:
      this.hasOuterBorder = true;
      this.hasToolbar = true;
      this.hasFullWidthContext = true;
    }

    this.dates = _.map(model.attributes.dates, function(date) {
      return app.utils.formatDateString(date);
    });

    this.repository = {};
    var ref = _.get(model, 'attributes.repository.ref');
    var name = _.get(model, 'attributes.repository._resolved.name');
    if(name && ref)
      this.repository.name = "<a href='"+ref+"'>"+name+"</a>";

    var contact = _.get(model, 'attributes.repository._resolved.agent_representation._resolved.agent_contacts[0]');

    if(contact) {

      if(contact.telephones) {
        this.repository.phone = _.map(contact.telephones, function(tele) {
          return tele.number
        }).join("<br />")
      }

      _.get(contact, 'telephones[0].number');
      this.repository.email = _.get(contact, 'email');

      this.repository.address = _.compact([
        _.get(contact, 'address_1'),
        _.get(contact, 'address_2'),
        _.get(contact, 'address_3'),
        _.get(contact, 'city'),
        _.get(contact, 'state'),
        _.get(contact, 'country'),
        _.get(contact, 'post_code')
      ]).join("<br />");
    }

    if(model.attributes.linked_agents && model.attributes.linked_agents.length) {
      var related_agents = {}
      _.forEach(model.attributes.linked_agents, function(agent_link) {
        related_agents[agent_link['role']] = related_agents[agent_link['role']] || [];
        related_agents[agent_link['role']].push(_.merge(agent_link._resolved, {relator: agent_link['relator']}));
      });

      var result = {}

      _.forEach(related_agents, function(agents, header) {
        agents.sort(function(agent) {
          return agent.title;
        });

        result[header] = _.map(agents, function(agent) {
          return "<a href='"+agent.uri+"'>"+agent.title+"</a>"+(agent.relator ? " ("+agent.relator+")" : "");
        });
      });

      this.related_agents = result;
    }


    if(model.attributes.subjects && model.attributes.subjects.length) {
      var sorted = _.compact(model.attributes.subjects).sort();

      this.subjects = _.map(sorted, function(obj) {
        return "<a href='"+obj._resolved.uri+"'>"+_.get(obj, '_resolved.title')+"</a>";
      });
    }

    if(model.attributes.classifications && model.attributes.classifications.length) {
      this.classifications = _.compact(_.map(model.attributes.classifications, function(obj) {
        var title = _.get(obj, '_resolved.title');
        var uri = _.get(obj, 'ref');
        return "<a href='"+uri+"'>"+title+"</a>";
      })).sort();
    }

    this.finding_aid_author = _.get(model.attributes, 'finding_aid_author');
    this.finding_aid_title = _.get(model.attributes, 'finding_aid_title');
    this.finding_aid_subtitle = _.get(model.attributes, 'finding_aid_subtitle');
    this.finding_aid_filing_title = _.get(model.attributes, 'finding_aid_filing_title');
    this.finding_aid_date = _.get(model.attributes, 'finding_aid_date');
    this.finding_aid_author = _.get(model.attributes, 'finding_aid_author');
    this.finding_aid_description_rules = _.get(model.attributes, 'finding_aid_description_rules');
    this.finding_aid_language = _.get(model.attributes, 'finding_aid_language');
    this.finding_aid_sponsor = _.get(model.attributes, 'finding_aid_sponsor');
    this.finding_aid_edition_statement = _.get(model.attributes, 'finding_aid_edition_statement');
    this.finding_aid_series_statement = _.get(model.attributes, 'finding_aid_series_statement');
    this.finding_aid_status = _.get(model.attributes, 'finding_aid_status');
    this.finding_aid_note = _.get(model.attributes, 'finding_aid_note');
  }

  RecordPresenter.prototype = Object.create(app.AbstractRecordPresenter.prototype);
  RecordPresenter.prototype.constructor = RecordPresenter;

  var RecordContainerView = Bb.View.extend({
    el: "#container",
    initialize: function(opts) {
      var $el = this.$el;

      this.on("recordloaded.aspace", function(model) {
        var recordType = model.attributes.jsonmodel_type;
        model.recordType = recordType;
        var presenter = new RecordPresenter(model);
        app.debug = {};
        app.debug.model = model;
        app.debug.presenter = presenter;

        //load the generic record template
        $el.html(app.utils.tmpl('record', presenter));
        $('.abstract', $el).readmore(300);


        if(_.includes(['resource', 'archival_object'], recordType)) {
          //add a metadata accordion for object records
          $("#record-accordion-container", $el).html(app.utils.tmpl('record-accordion', presenter));

          //add a tree sidebar
          var opts = {
            recordUri: presenter.uri
          };
          this.sidebarView = new app.ResourceTreeSidebar(opts);
        }

        //add an embedded search / browse for concept records
        if(_.includes(['classification', 'classification_term'], recordType)) {
          var embeddedSearchView = new app.EmbeddedSearchView({
            filters: [{"classification_uris": presenter.uri}]
          });

        }

        //build tree sidebar
        // TODO - resource and AO trees
        if(_.includes(['classification', 'classification_term'], recordType)) {
          this.sidebarView = new app.ClassificationSidebarView(model.attributes.uri);
        }

      });

      this.model = new app.RecordModel(opts);
      this.render();
    },

    render: function() {
      var model = this.model;
      var presenter;
      var $el = this.$el;
      var that = this;

      // $('#search-box').remove();
      // $('#welcome').remove();
      $('#wait-modal').foundation('open');

      model.fetch().then(function() {
        that.trigger("recordloaded.aspace", model);
      }).fail(function(response) {
        var errorView = new app.ServerErrorView({
          response: response
        });

        $el.html(errorView.$el.html());
      }).always(function() {
        setTimeout(function() {
          try {
            $('#wait-modal').foundation('close');
            $('#container').foundation();
          } catch(e) {
          }
        }, 500);
      });

    }
  });


  var RecordModel = Bb.Model.extend({
    initialize: function(opts) {
      this.recordTypePath = opts.recordTypePath;
      this.id = opts.id;
      this.scope = opts.repoId ? 'repository' : 'global'
      if(this.scope === 'repository')
        this.repoId = opts.repoId;

      return this;
    },

    url: function() {
      var url = RAILS_API;
      var asType = app.utils.getASType(this.recordTypePath);
      if(this.scope === 'repository') {
        url += "/repositories/" + this.repoId;
      }

      url += "/" + _.pluralize(asType) + "/" + this.id;

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

  });

  app.RecordModel = RecordModel;
  app.RecordContainerView = RecordContainerView;

})(Backbone, _, jQuery);
