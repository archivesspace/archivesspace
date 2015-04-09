(function ($) {
  $.jstree.defaults.select_limit = 20;

  $.jstree.plugins.select_limit = function (options, parent) {
    // own function
    this.select_node = function (obj, supress_event, prevent_open) {
      if(this.settings.select_limit > this.get_selected().length) {
        parent.select_node.call(this, obj, supress_event, prevent_open);
      }
    };
  };
})(jQuery);
