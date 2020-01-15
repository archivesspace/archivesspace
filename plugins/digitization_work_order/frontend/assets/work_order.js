var WorkOrderToolbarAction = function() {
  this.setupButton();
};


WorkOrderToolbarAction.prototype.setupButton = function() {
  this.$button = $(AS.renderTemplate("workOrderButtonTemplate"));

  var $btnGroup = $("<div>").addClass("btn-group");

  this.$button.appendTo($btnGroup);
  $btnGroup.appendTo($("#archives_tree_toolbar .btn-toolbar"));
}


// if a resource tree page, setup the work order toolbar action
$(document).on("loadedrecordform.aspace", function(event, $container) {
  // are we dealing with a record with a tree?
  if ($(".archives-tree").data("read-only") || $container.is("#archives_tree_toolbar")) {
    // is the tree a resource tree?
    if (AS._tree && AS._tree.get_json()[0].type == "resource") {
      // hurray! add the button.
      new WorkOrderToolbarAction();
    }
  }
});
