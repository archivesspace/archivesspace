var app = app || {};
(function(Bb, _, $) {


  var ClassificationSidebarView = Bb.View.extend({
    el: "#sidebar-container",

    initialize: function(nodeUri) {
      this.url = "/api"+nodeUri+"/tree";
      this.render();
    },

    render: function() {
      var $el = this.$el;

      $el.addClass('classification-tree');

      $.ajax(this.url, {
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


          $el.html(app.utils.tmpl('classification-tree', {classifications: data, displayString: displayString, containerUri: containerUri, title: "Subgroups of the Record Group"}));

          $(".classification-tree").foundation();
        }
      });
    }

  });

  app.ClassificationSidebarView = ClassificationSidebarView;

})(Backbone, _, jQuery);
