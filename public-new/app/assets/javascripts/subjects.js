var app = app || {};
(function(Bb, _, $) {

  function SubjectPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);
    this.source = model.attributes.source;

  }

  SubjectPresenter.prototype = Object.create(app.AbstractRecordPresenter.prototype);
  SubjectPresenter.prototype.constructor = SubjectPresenter;



  var SubjectModel = Bb.Model.extend({
    initialize: function(opts) {
      this.recordType = 'subject';
      this.id = opts.id
      return this;
    },

    url: function() {
      var url = RAILS_API + "/subjects/" + this.id;

      return url;
    }

  });


  var SubjectContainerView = Bb.View.extend({
    el: "#container",

    initialize: function(opts) {
      this.model = new SubjectModel(opts);
      var $el = this.$el;

      this.on("recordloaded.aspace", function(model) {
        var presenter = new SubjectPresenter(model);
        app.debug = {};
        app.debug.model = model;
        app.debug.presenter = presenter;

        $el.html(app.utils.tmpl('record', presenter));
        $('.abstract', $el).readmore(300);

        var embeddedSearchView = new app.EmbeddedSearchView({
          filters: [{"subjects": model.attributes.title}]
        });

        // var nameSidebarView = new NameSidebarView({
        //   presenter: presenter
        // });

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

  app.SubjectContainerView = SubjectContainerView;

})(Backbone, _, jQuery);
