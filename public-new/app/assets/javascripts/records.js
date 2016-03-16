var app = app || {};
(function(Bb, _, $) {

  function RecordPresenter(model) {

    this.representativeImage = _.get(model, 'attributes.representative_image.file_uri')

    this.representativeImageCaption = _.get(model, 'attributes.representative_image.caption') || "<i>No caption</i>";

    if(model.attributes.title) {
      this.title = model.attributes.title;
    } else if(model.attributes.jsonmodel_type == 'accession') {
      this.title = model.attributes.id_0;
    } else {
      this.title = "NO TITLE";
    }

    if(model.attributes.repository && model.attributes.repository._resolved) {
      this.repositoryName = model.attributes.repository._resolved.name;
    }

    this.language = _.get(model, 'attributes.language');

    this.recordType = model.attributes.jsonmodel_type;
    this.recordTypeLabel =  app.utils.getPublicTypeLabel(this.recordType);
    this.recordTypeIconClass = "fi-home";

    this.abstract = "Contents of the abstract field. Maecenas faucibus mollis. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.";

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
      this.recordTypeIconClass = "fi-page-multiple";
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
      this.recordTypeIconClass = "fi-page-multiple";
      // this.hasAccordion = false;
      this.hasOuterBorder = false;
      this.hasContentSidebar = true;
      this.hasToolbar = false;
      this.hasFullWidthContext = false;
      break;

    default:
      // this.hasAccordion = true;
      this.hasOuterBorder = true;
      this.hasToolbar = true;
      this.hasFullWidthContext = true;
    }

    if(model.attributes.identifier) {
      this.identifier = model.attributes.identifier;
    } else if(model.attributes.id_0) {
      this.identifier = model.attributes.id_0;
    } else if(model.attributes.digital_object_id) {
      this.identifier = model.attributes.digital_object_id;
    } else {
      this.identifier = "NO ID";
    }



    this.dates = _.map(model.attributes.dates, function(date) {
      return app.utils.formatDateString(date);
    });

    if(true) { // really: if scope === repo
      this.repository = {};
      this.repository.name = _.get(model, 'attributes.repository._resolved.name');

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

    if(model.attributes.linked_agents && model.attributes.linked_agents.length) {
      var related_agents = {}
      _.forEach(model.attributes.linked_agents, function(agent_link) {
        related_agents[agent_link['role']] = related_agents[agent_link['role']] || [];
        related_agents[agent_link['role']].push(agent_link._resolved.title);
      });

      _.forEach(related_agents, function(agents, header) {
        agents.sort();
      });

      this.related_agents = related_agents;
    }


    if(model.attributes.subjects && model.attributes.subjects.length) {
      this.subjects = _.compact(_.map(model.attributes.subjects, function(obj) {
        return _.get(obj, '_resolved.title');
      })).sort();
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


  RecordPresenter.prototype.has = function(key) {
    return !_.isUndefined(this[key])
  };

  RecordPresenter.prototype.present = function(key) {
    if (_.isUndefined(this[key])) {
      return false;
    } else if (_.isArray(this[key]) && this[key].length < 1) {
      return false;
    } else {
      return true;
    }
  };


  var SidebarTreeView = Bb.View.extend({
    el: "#sidebar-container",
    initialize: function(nodeUri) {
      this.nodeUri = nodeUri;
      this.render();
    },

    render: function() {
      var presenter = {};
      var that = this;
      presenter.title = "Subgroups of the Record Group";

      this.$el.html(app.utils.tmpl('sidebar-tree', presenter));
      var url = "/api"+that.nodeUri+"/tree";
      console.log(url);

      $.ajax(url, {
        success: function(data) {
          app.debug.tree = data;

          //TODO - make once
          var displayString = function(container_child) {
            var result = container_child.container_1;
            result += _.has(container_child, 'container_2') ? container_child.container_2 : '';
            return result;
          };

          var containerUri = function (container_child) {
            var result = container_child.resource_data.repository + "/" + _.pluralize(app.utils.getPublicType(container_child.resource_data.type)) + "/" + container_child.resource_data.id;

            return result;
          };


          $("#tree-container").html(app.utils.tmpl('classification-tree', {classifications: data, displayString: displayString, containerUri: containerUri}));

          $("#tree-container").foundation();

        }
      });

      // $("#tree-container").jstree({
      //   core: {
      //     data: function(node, cb) {
      //       if(node.id === '#') {
      //         var url = "/api/trees?node_uri=" + that.nodeUri;

      //         $.ajax(url, {
      //           success: function(data) {
      //             console.log(data);
      //             var childrenData = _.map(data.direct_children, function(dc){
      //               return {
      //                 id: 1,
      //                 text: dc['title'],
      //                 children: [{id:2, text:"foo"}]
      //               };
      //             });
      //             console.log(childrenData);
      //             cb(childrenData);
      //           }
      //         });
      //       } else {
      //         console.log("else")
      //       }
      //     }

          // data: {
          //   url: function(obj) {
          //     var url = "/api/trees?node_uri=" + that.nodeUri;
          //     console.log(url);
          //     return url
          //   },
          //   data: function(treeNode) {
          //     console.log("treeNode");
          //     console.log(treeNode);
          //     return {
          //       id: 100,
          //       text: "foo"
          //     }
          //   }
          // }

    },

    events: {
      "click .classification-term a": function(e) {
        e.stopPropagation();
        // e.preventDefault();
        // TODO - catch this and avoid page load
      }
    }
  });


  var RecordContainerView = Bb.View.extend({
    el: "#container",
    initialize: function(opts) {
      var $el = this.$el;

      this.on("recordloaded.aspace", function(model) {
        var presenter = new RecordPresenter(model);
        var recordType = model.attributes.jsonmodel_type;
        app.debug = {};
        app.debug.model = model;
        app.debug.presenter = presenter;

        //load the generic record template
        $el.html(app.utils.tmpl('record', presenter));
        $('.abstract', $el).readmore(300);

        //add a metadata accordion for object records
        if(_.includes(['resource', 'archival_object'], recordType)) {
          $("#record-accordion-container", $el).html(app.utils.tmpl('record-accordion', presenter));
        }

        //add an embedded search / browse for concept records
        if(_.includes(['classification', 'classification_term'], recordType)) {
          var embeddedSearchView = new app.EmbeddedSearchView();
          // $("#embedded-search-container", $el).append(embeddedSearchView.$el);
        }

        //build tree sidebar
        // TODO - resource and AO trees
        if(_.includes(['classification', 'classification_term', '__resource', '__archival_object'], recordType)) {
          this.sidebarView = new SidebarTreeView(model.attributes.uri);
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

      $('#search-box').remove();
      $('#welcome').remove();
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
          $('#wait-modal').foundation('close');
          $('#container').foundation();
        }, 500);
      });

    }
  });


  var RecordModel = Bb.Model.extend({
    initialize: function(opts) {
      this.recordType = opts.recordType;
      this.id = opts.id;
      this.scope = opts.repoId ? 'repository' : 'global'
      if(this.scope === 'repository')
        this.repoId = opts.repoId;

      return this;
    },

    url: function() {
      var url = RAILS_API;
      var asType = app.utils.getASType(this.recordType);
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
