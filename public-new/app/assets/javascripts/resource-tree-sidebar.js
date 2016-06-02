var app = app || {};
(function(Bb, _, $) {

  var baseUrl = RAILS_API+"/trees?node_uri=";

  var ResourceTreeSidebar = Bb.View.extend({
    el: "#sidebar-container",

    initialize: function(opts){
      this.recordUri = opts.recordUri;
      var rootUrl = baseUrl+this.recordUri;
      this.$el.html(app.utils.tmpl('resource-tree-sidebar'));
      this.$el.addClass("resource-tree-sidebar");
      var that = this;

      $("#tree-container").jstree({
        plugins: ['types'],
        core: {
          data: function(obj, cb) {
            var url = obj.id === '#' ? rootUrl : baseUrl+obj.original.record_uri;

            $.ajax(url, {
              success: function(data) {
                _.forEach(data, function(node) {
                  node.text = app.utils.tmpl('resource-tree-node', node);

                  if(node.container_label) {
                    node.type = 'has_container';
                  }
                  node.a_attr = {
                    "href": app.utils.getPublicUrl(node.record_uri, 'archival_object'),
                    "title": node.title
                  };
                });
                console.log(data);


                cb(data);
              }
            });
          },


          themes: {
            dots: false
          },

        },

        types: {
          "default": {
            "icon": "fi-folder"
          },
          "has_container": {
            "icon": "fi-archive",
            "li_attr": {
              "class": "container-node"
            }
          }
        }
      }).bind("select_node.jstree", function(event, data) {
        console.log(data);
        app.router.showRecord(data.node.a_attr.href);
      });

    }


  });


  app.ResourceTreeSidebar = ResourceTreeSidebar;

})(Backbone, _, jQuery);
