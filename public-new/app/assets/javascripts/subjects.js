var app = app || {};
(function(Bb, _, $) {

  function SubjectPresenter(model) {
    app.AbstractRecordPresenter.call(this, model);
    this.source = model.attributes.source;

    // TODO - this is the same as agents. can
    // it be de-duped?
    if(model.attributes.external_documents && model.attributes.external_documents.length) {
      this.externalDocuments = "<ul>"+_.map(model.attributes.external_documents, function(doc) {
        return "<li>"+doc.title+"</li>";
      }).join('') + "<ul />";
    }

    if(model.attributes.terms && model.attributes.terms.length) {
      var termsByType = {};
      _.forEach(model.attributes.terms, function(term) {
        if(!termsByType[term['term_type']])
          termsByType[term['term_type']] = [];

        termsByType[term['term_type']].push(term['term']);

      });

      var result = "<ul>";
      _.forEach(_.keys(termsByType).sort(), function(type){
        result += "<li>" + type + "<ul>";
        _.forEach(termsByType[type].sort(), function(term){
          result += "<li>"+term+"</li>";
        });
        result += "</ul></li>";

      });
      result += "</ul>";

      this.terms = result;
    }
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

        var moreAboutSubjectSidebarView = new MoreAboutSubjectSidebarView({
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


  var MoreAboutSubjectSidebarView = Bb.View.extend({
    el: "#sidebar-container",

    initialize: function(opts) {
      this.presenter = opts.presenter;
      this.render();
    },

    render: function() {
      this.$el.addClass('more-about-subject-sidebar');
      this.$el.html(app.utils.tmpl('more-about-subject', this.presenter, true))

      this.$el.foundation();
    }
  });

  app.SubjectContainerView = SubjectContainerView;

})(Backbone, _, jQuery);
