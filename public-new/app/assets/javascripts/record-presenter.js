var app = app || {};
(function(Bb, _, $) {

  var AbstractRecordPresenter = function(model) {
    this.hasOuterBorder = false;
    this.hasFullWidthContext = false;
    this.hasToolbar = false;
    this.hasContentSidebar = true;
    this.repositoryName = "Repository Name";
    this.repositoryPublicUrl = "#";

    this.uri = _.get(model, 'attributes.uri');
    this.title = _.get(model, 'attributes.title');
    this.language = _.get(model, 'attributes.language');
    this.recordType = model.attributes.jsonmodel_type;

    if(this.recordType === 'archival_object' && model.attributes.instances.length && model.attributes.instances[0].container) {
      var firstContainer = model.attributes.instances[0].container;
      var label = firstContainer.type_1 + " " + firstContainer.indicator_1 + " " + firstContainer.type_2 + " " + firstContainer.indicator_2;
      this.recordTypeLabel = label;

    } else {
      this.recordTypeLabel =  app.utils.getPublicTypeLabel(this.recordType);
    }

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
      this.repositoryPublicUrl = app.utils.getPublicUrl(model.attributes.repository.ref, 'repository');
    }

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
