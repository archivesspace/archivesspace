var app = app || {};
(function(Bb, _, $) {


  function AgentPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);
    this.recordTypeIconClass = "fi-torso";
  }

  AgentPresenter.prototype = Object.create(app.AbstractRecordPresenter.prototype);
  AgentPresenter.prototype.constructor = AgentPresenter;


  var AgentModel = Bb.Model.extend({
    initialize: function(opts) {
      console.log(opts);
      this.recordType = app.utils.getASType(opts.type);
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
      this.render();
      var $el = this.$el;

      this.on("recordloaded.aspace", function(model) {
        var presenter = new AgentPresenter(model);
        app.debug = {};
        app.debug.model = model;
        app.debug.presenter = presenter;

        $el.html(app.utils.tmpl('record', presenter));
        $('.abstract', $el).readmore(300);

      });

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

  app.AgentContainerView = AgentContainerView;

})(Backbone, _, jQuery);
