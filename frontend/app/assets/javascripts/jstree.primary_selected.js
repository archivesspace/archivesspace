(function (factory) {
  "use strict";
  if (typeof define === 'function' && define.amd) {
    define('jstree.primary_selected', ['jquery','jstree'], factory);
    }
  else if(typeof exports === 'object') {
    factory(require('jquery'), require('jstree'));
    }
  else {
    factory(jQuery, jQuery.jstree);
    }
}(function ($, jstree, undefined) {
  "use strict";

  if($.jstree.plugins.primary_selected) { return; }

  $.jstree.plugins.primary_selected = function (options, parent) {

    this.ensure_sole_selected = function(obj) {
      obj = this.get_node(obj);

      // important!
      if (this.get_selected()[0] == obj.id)
        return;

      this.deselect_all();
      this.select_node(obj);
    };


    this.primary = function(cb) {
      cb(this.get_primary_selected(true));
    }


    this.get_primary_selected_dom = function() {
      return this.get_node(this.get_primary_selected(), true);
    }

    this.get_primary_selected = function(full) {
      var obj_id = this._data.core.primary_selected;
      if (typeof(obj_id) === 'undefined')
        return false;

      return full ? this.get_node(obj_id) : obj_id
    };

    this.set_primary_selected = function(obj, cb) {
      if (obj === '#') {
        var root = this.get_node(obj);
        obj = root.children[0];
      }

      obj = this.get_node(obj);
      if (!obj || obj.id === '#') {
        return false;
      }

      // clear the old if it exists
      if (this._data.core.primary_selected) {
        var old = this.get_node(this._data.core.primary_selected);
        if (old) {
          old.state.primary_selected = false;
          var old_dom = this.get_node(old, true);
          old_dom.removeClass("primary-selected");
        }
        this._data.core.primary_selected = undefined;
      }

      var dom = this.get_node(obj, true);

      if (!obj.state.primary_selected) {        
        obj.state.primary_selected = true;
        this._data.core.primary_selected = obj.id
        if (dom && dom.length) {
          dom.addClass("primary-selected");
        }
      }

      // make sure to do this last so
      // those listenting to 'select_node'
      // can know what's up
      this.ensure_sole_selected(obj);

      if (typeof(cb) != 'undefined') {
        cb(obj);
      }

    };


    this.refresh_primary_selected = function() {
      this.set_primary_selected(this.get_primary_selected());
    }

  };

}));
