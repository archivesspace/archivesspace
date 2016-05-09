var app = app || {};
(function(Bb, _, $) {

  function contactValue(model) {
    try {
      return model.attributes.agent_representation._resolved.agent_contacts[0].name;
    } catch(e) {
      return model.attributes.name;
    }
  }

  function locationValue(model) {
    var contact = _.get(model.attributes, "agent_representation._resolved.agent_contacts[0]");
    if(_.isUndefined(contact))
      return "Location unknown";

    var result = "";
    if(_.has(contact, 'address_1'))
      result += contact.address_1;

    if(_.has(contact, 'address_2'))
      result += " " + contact.address_2;

    if(_.has(contact, 'address_3'))
      result += " " + contact.address_3;

    if(_.has(contact, 'city'))
      result += ". " + contact.city;

    if(_.has(contact, "country"))
      result += ". " + contact.country;

    return result;

  }

  function openingHoursValue(model) {
    return "8:00am – 10:00am";
  }

  function RepoPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);

    this.hasContentSidebar = false;
    this.hasFullWidthContext = true;

    this.title = model.attributes.name;
    this.identifier = model.attributes.repo_code;

    this.abstract = "<p>WHERE DOES THIS FIELD GET POPULATED FROM</p><p><strong>Contact:</strong> "+contactValue(model)+"<br /><strong>Location:</strong> "+locationValue(model)+"<br /><strong>Opening Hours:</strong> "+openingHoursValue(model);

  };

  RepoPresenter.prototype = Object.create(app.AbstractRecordPresenter.prototype);
  RepoPresenter.prototype.constructor = RepoPresenter;


  var RepoModel = Bb.Model.extend({
    initialize: function(opts) {
      this.recordType = 'repository';
      this.id = opts.id;
      return this;
    },

    url: function() {
      return RAILS_API+"/repositories/"+this.id
    }
  });

  var RepoContainerView = Bb.View.extend({
    el: "#container",

    initialize: function(opts) {
      this.model = new RepoModel(opts);
      var $el = this.$el;
      var embeddedSearchPage = opts.page || 1;
      var embeddedSearchBaseUrl = "/repositories/"+opts.id;

      this.on("recordloaded.aspace", function(model) {
        var presenter = new RepoPresenter(model);
        app.debug = {};
        app.debug.model = model;

        $el.html(app.utils.tmpl('record', presenter));


        var whatsInRepoPresenter = {
          resourceIconClass: app.icons.getIconClass('resource'),
          resourceCount: 100,
          resourceLabelPlural: "Resources",

          archivalObjectIconClass: app.icons.getIconClass('archival_object'),
          archivalObjectCount: 100,
          archivalObjectLabelPlural: "Records",

          agentPersonIconClass: app.icons.getIconClass('agent_person'),
          agentPersonCount: 100,
          agentPersonLabelPlural: "People",

          subjectIconClass: app.icons.getIconClass('subject'),
          subjectCount: 100,
          subjectLabelPlural: "Subjects",

          classificationIconClass: app.icons.getIconClass('classification'),
          classificationCount: 100,
          classificationLabelPlural: "Record Groups"
        }

        // maybe make a separate view for this
        // TODO - figure out how to load real stats
        $('#whats-in-repo-container', $el).addClass('row collapse');
        $('#whats-in-repo-container', $el).html(app.utils.tmpl('whats-in-repo', whatsInRepoPresenter));

        var embeddedSearchView = new app.EmbeddedSearchView({
          filters: [{"repository": model.attributes.uri}],
          title: "Search This Repository",
          currentPage: embeddedSearchPage,
          baseUrl: embeddedSearchBaseUrl
        });

      });

      this.render();
    },

    //TODO: factor this out to a single function
    // for all record containers
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

  app.RepoContainerView = RepoContainerView;

})(Backbone, _, jQuery);
