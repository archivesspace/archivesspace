var app = app || {};
(function(Bb, _, $) {

  function formatName(name) {
    var result = ""
    if(name.rest_of_name) {
      result = result+name.rest_of_name + " ";
    }
    result = result + name.primary_name;
    if(name.dates) {
      result = result+"&#160;(Dates: "+name.dates+")";
    }

    return result;
  }


  function AgentPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);

    var nameList = "<ul>";
    _.forEach(model.attributes.names, function(name) {
      nameList = nameList+"<li>"+formatName(name)+"</li>";
    });
    nameList = nameList + "</ul>"

    this.nameList = nameList;

    var relations = {}

    _.forEach(model.attributes.related_agents, function(agent_link) {
      if(!relations[agent_link['relator']])
        relations[agent_link['relator']] = [];

      relations[agent_link['relator']].push(agent_link._resolved.display_name.sort_name);
    })

    this.relatedAgents = relations;

    if(model.attributes.external_documents && model.attributes.external_documents.length) {
      this.externalDocuments = "<ul>"+_.map(model.attributes.external_documents, function(doc) {
        return "<li>"+doc.title+"</li>";
      }).join('') + "<ul />";
    }

    if(model.attributes.rights_statements) {
      this.rightsStatements = _.map(model.attributes.rights_statements, function(statement) {
        return app.utils.formatRightsStatement(statement);
      });
    }
  }

  AgentPresenter.prototype = Object.create(app.AbstractRecordPresenter.prototype);
  AgentPresenter.prototype.constructor = AgentPresenter;


  var AgentModel = Bb.Model.extend({
    initialize: function(opts) {
      this.recordType = opts.asType || app.utils.getASType(opts.type);
      this.id = opts.id
      return this;
    },

    url: function() {
      var url = RAILS_API;

      switch(this.recordType) {
      case 'agent_person':
        url = url + "/people/" + this.id;
        break;
      }

      return url;
    }

  });


  var AgentContainerView = Bb.View.extend({
    el: "#container",

    initialize: function(opts) {
      this.model = new AgentModel(opts);
      var $el = this.$el;

      this.on("recordloaded.aspace", function(model) {
        var presenter = new AgentPresenter(model);
        app.debug = {};
        app.debug.model = model;
        app.debug.presenter = presenter;

        $el.html(app.utils.tmpl('record', presenter));
        $('.abstract', $el).readmore(300);

        var embeddedSearchView = new app.EmbeddedSearchView({
          filters: [{"agent_uris": presenter.uri}],
          sortKey: presenter.uri.replace(/\//g, '_')+"_relator_sort asc"
        });

        var nameSidebarView = new NameSidebarView({
          presenter: presenter
        });

      });

      this.render();
    },

    render: function() {
      var that = this;
      var model = this.model;

      $('#wait-modal').foundation('open');

      this.model.fetch().then(function() {
        that.trigger("recordloaded.aspace", model);
      }).fail(function(response) {
        var errorView = new app.ServerErrorView({
          response: response
        });

        that.$el.html(errorView.$el.html());
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


  var NameSidebarView = Bb.View.extend({
    el: "#sidebar-container",

    initialize: function(opts) {
      this.presenter = opts.presenter;
      this.render();
    },

    render: function() {
      this.$el.addClass('name-sidebar');
      this.$el.html(app.utils.tmpl('more-about-name', this.presenter, true));

      this.$el.foundation();
    }

  });

  app.AgentContainerView = AgentContainerView;

})(Backbone, _, jQuery);
