var app = app || {};

(function(Bb, _) {
  'use strict';

  var typeToIconMap = {
    resource: "glyphicon glyphicon-list-alt",
    accession: "glyphicon glyphicon-list-alt",
    classification: "fi-page-multiple",
    classification_term: "fi-page-multiple",
    subject: "glyphicon glyphicon-tags",
    agent_person: "fi-torso",
    agent_corporation: "glyphicon glyphicon-briefcase",
    agent_family: "torsos-male-female",
    repository: "fi-home"
  };

  app.icons = {
    getIconClass: function(recordType) {
      return typeToIconMap[recordType];
    }
  };

})(Backbone, _);
