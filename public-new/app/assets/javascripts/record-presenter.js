var app = app || {};
(function(Bb, _, $) {

  var AbstractRecordPresenter = function(model) {
    this.hasOuterBorder = false;
    this.hasFullWidthContext = false;
    this.hasToolbar = false;
    this.hasContentSidebar = true;
    this.repositoryName = "";

    this.uri = _.get(model, 'attributes.uri');
    this.title = _.get(model, 'attributes.title');
    this.language = _.get(model, 'attributes.language');
    this.recordType = model.recordType;
    this.recordTypeLabel =  app.utils.getPublicTypeLabel(this.recordType);

    if(this.recordType)
      this.recordTypeIconClass = app.icons.getIconClass(this.recordType);

    if(model.attributes.identifier) {
      this.identifier = model.attributes.identifier;
    } else if(model.attributes.id_0) {
      this.identifier = model.attributes.id_0;
    } else if(model.attributes.digital_object_id) {
      this.identifier = model.attributes.digital_object_id;
    } else {
      this.identifier = _.get(model, 'attributes.uri');
    }

    this.abstract = "Contents of the abstract field. Maecenas faucibus mollis. Maecenas sed diam eget risus varius blandit sit amet non magna. Vestibulum id ligula porta semper.";

    if(model.attributes.repository && model.attributes.repository._resolved) {
      this.repositoryName = model.attributes.repository._resolved.name;
    }

    this.recordType = model.attributes.jsonmodel_type;
    this.recordTypeLabel =  app.utils.getPublicTypeLabel(this.recordType);

  };


  AbstractRecordPresenter.prototype.has = function(key) {
    return !_.isUndefined(this[key])
  };

  AbstractRecordPresenter.prototype.present = function(key) {
    if (_.isUndefined(this[key])) {
      return false;
    } else if (_.isArray(this[key]) && this[key].length < 1) {
      return false;
    } else {
      return true;
    }
  };

  app.AbstractRecordPresenter = AbstractRecordPresenter;

})(Backbone, _, jQuery);
